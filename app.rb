require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'json'
require 'dotenv'
require 'http'
require 'slack-ruby-client'

Dotenv.load


post '/callback' do
  request_body = JSON.parse(request.body.read)
  case request_body['type']
  when 'url_verification'
    request_body['challenge']
  when 'event_callback'
    if request_body['event']['channel'] == 'C012PCA7X1B'
      message = request_body['event']['text']

      request_content = {
        'key' => ENV['USER_LOCAL_TOKEN'],
        'message' => CGI.escape(message)
      }
      request_params = request_content.reduce([]) do |params, (key, value)|
        params << "#{key}=#{value}"
      end
      chat_response = HTTP.get('https://chatbot-api.userlocal.jp/api/chat?' + request_params.join('&'))
      return_result = JSON.parse(chat_response)
      puts return_result

      slack_response = HTTP.post(
        'https://slack.com/api/chat.postMessage',
        params: {
          token: ENV['SLACK_API_TOKEN'],
          channel: '#times_webyko',
          text: return_result['result'],
          as_user: true
        }
      )
      'ok'
    end
  end
end
