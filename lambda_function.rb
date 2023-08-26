# frozen_string_literal: true

require 'slack-notifier'
require 'aws-sdk-costexplorer'
require 'net/http'
require 'uri'
require 'json'

EXCHANGE_RATE_URL = "https://openexchangerates.org/api/latest.json?app_id=#{ENV['OPENEXCHANGERATES_API_ID']}"

def lambda_handler(*)
  puts 'ok, called lambda handler'

  message = fetch_cost
  puts 'ok, fetched cost'

  result = pretty_response(message)
  puts 'ok, formatted response'

  notify_slack(result)
  puts 'ok, notify slack finished'
end

def fetch_cost
  aws_client = Aws::CostExplorer::Client.new(region: 'us-east-1')

  aws_client.get_cost_and_usage(
    time_period: {
      start: Date.new(Date.today.year, Date.today.month, 1).strftime('%F'),
      end: Date.new(Date.today.year, Date.today.month, -1).strftime('%F')
    },
    granularity: 'MONTHLY',
    metrics: ['AmortizedCost'],
    group_by: [{ type: 'DIMENSION', key: 'SERVICE' }]
  )
end

def pretty_response(message)
  sum, cost_groups = summerize_cost_groups(message.dig(:results_by_time, 0, :groups), exchange_rate)

  start_date = message.dig(:results_by_time, 0, :time_period, :start)
  end_date = message.dig(:results_by_time, 0, :time_period, :end)

  <<~"RESPONSE"
    ===========================
    #{start_date} - #{end_date}
    ---------------------------
    合計 : #{round(sum)}円
    #{cost_groups.join("\n")}
    ===========================
  RESPONSE
end

def exchange_rate
  uri = URI.parse(EXCHANGE_RATE_URL)
  res = Net::HTTP.get(uri)
  JSON.parse(res)['rates']['JPY']
end

def summerize_cost_groups(cost_groups, rate)
  sum = 0
  formatted_cost_groups = cost_groups.map do |group|
    amount = group.dig(:metrics, 'AmortizedCost', :amount).to_f * rate
    sum += amount
    "#{group.dig(:keys, 0)} : #{round(amount)}円"
  end

  [sum, formatted_cost_groups]
end

def round(amount)
  amount.round
end

def notify_slack(result)
  notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK_URL']
  notifier.ping result
end
