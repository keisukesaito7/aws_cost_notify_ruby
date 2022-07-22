require 'slack-notifier'
require 'aws-sdk-costexplorer'

def lambda_handler(event:, context:)
  message = fetch_cost
  result = pretty_response(message)
  notify_slack(result)
end

def fetch_cost
  aws_client = Aws::CostExplorer::Client.new(region: "us-east-1")

  aws_client.get_cost_and_usage(
    time_period: {
      start: Date.new(Date.today.year, Date.today.month, 1).strftime('%F'),
      end: Date.new(Date.today.year, Date.today.month, -1).strftime('%F'),
    },
    granularity: 'MONTHLY',
    metrics: ['AmortizedCost'],
    group_by: [ { type: "DIMENSION",key: 'SERVICE' }]
  )
end

def pretty_response(message)
  start_date = message.dig(:results_by_time, 0, :time_period, :start)
  end_date = message.dig(:results_by_time, 0, :time_period, :end)

  sum = 0
  cost_groups = message.dig(:results_by_time, 0, :groups).map do |group|
    key = group.dig(:keys, 0)
    amount = group.dig(:metrics, "AmortizedCost", :amount).to_f.round(2)
    unit = group.dig(:metrics, "AmortizedCost", :unit)

    sum += amount

    "#{key}: #{amount} #{unit}"
  end

  <<~"EOS"
    ===========================
    #{start_date} - #{end_date}
    ---------------------------
    sum: #{sum} USD
    #{cost_groups.join("\n")}
    ===========================
  EOS
end

def notify_slack(result)
  notifier = Slack::Notifier.new ENV.fetch('SLACK_WEBHOOK_URL')
  notifier.ping result
end
