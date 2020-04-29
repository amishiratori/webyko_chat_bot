require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'json'
require 'dotenv'
require 'http'
require 'slack-ruby-client'

Dotenv.load

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

post '/callback' do
  request_body = JSON.parse(request.body.read)
  case request_body['type']
  when 'url_verification'
    request_body['challenge']
  end
end
