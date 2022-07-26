# frozen_string_literal: true

require 'slack-notifier'
require 'aws-sdk-costexplorer'
require 'net/http'
require 'uri'
require 'json'

def lambda_handler(*)
  message = fetch_cost
  result = pretty_response(message)
  notify_slack(result)
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
  start_date = message.dig(:results_by_time, 0, :time_period, :start)
  end_date = message.dig(:results_by_time, 0, :time_period, :end)

  rate = exchange_rate_from_dollar_to_yen
  sum, cost_groups = summerize_cost_groups(message.dig(:results_by_time, 0, :groups), rate)

  <<~"RESPONSE"
    ===========================
    #{start_date} - #{end_date}
    ---------------------------
    合計 : #{round(sum)}円
    #{cost_groups.join("\n")}
    ===========================
  RESPONSE
end

def exchange_rate_from_dollar_to_yen
  uri = URI.parse("https://openexchangerates.org/api/latest.json?app_id=#{ENV['OPENEXCHANGERATES_API_ID']}")
  res = Net::HTTP.get(uri)
  JSON.parse(res)['rates']['JPY']
end

def summerize_cost_groups(cost_groups, rate)
  sum = 0
  formatted_cost_groups = cost_groups.map do |group|
    amount = exchange_from_dollar_to_yen({
                                           amount: group.dig(:metrics, 'AmortizedCost', :amount).to_f,
                                           rate: rate
                                         })
    sum += amount
    "#{group.dig(:keys, 0)} : #{round(amount)}円"
  end

  [sum, formatted_cost_groups]
end

def exchange_from_dollar_to_yen(amount:, rate:)
  amount * rate
end

def round(amount)
  amount.round
end

def notify_slack(result)
  notifier = Slack::Notifier.new ENV.fetch('SLACK_WEBHOOK_URL')
  notifier.ping result
end
