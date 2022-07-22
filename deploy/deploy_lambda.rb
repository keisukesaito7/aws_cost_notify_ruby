require "aws-sdk-lambda"

client = Aws::Lambda::Client.new region: ENV["resion"],
                             access_key_id: ENV["access_key_id"],
                             secret_access_key: ENV["secret_access_key"]

zip_file = File.open "costNotifierRuby.zip", "r"
client.update_function_code function_name: "costNotifierRuby", zip_file: zip_file