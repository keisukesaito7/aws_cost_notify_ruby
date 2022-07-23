# frozen_string_literal: true

require 'aws-sdk-lambda'

client = Aws::Lambda::Client.new({
                                   region: ENV['REGION'],
                                   access_key_id: ENV['ACCESS_KEY_ID'],
                                   secret_access_key: ENV['SECRET_ACCESS_KEY']
                                 })

zip_file = File.open 'costNotifierRuby.zip', 'r'

client.update_function_code({
                              function_name: 'costNotifierRuby',
                              zip_file: zip_file
                            })
