# frozen_string_literal: true

require 'aws-sdk-lambda'

client = Aws::Lambda::Client.new({ region: ENV['REGION'] })

# function deploy
functions_zip = File.open 'functions.zip', 'r'

# function 更新 (コンソールから関数を用意)
client.update_function_code(
  {
    function_name: 'costNotifierRuby',
    zip_file: functions_zip
  }
)

# layer deploy
layer_zip = File.opne 'layer.zip', 'r'

# layer update のコード

