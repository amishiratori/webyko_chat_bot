require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'json'
require 'dotenv'
require 'net/http'
require 'slack-ruby-client'
require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require './models'

Dotenv.load

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'TEST'.freeze
CREDENTIALS_PATH = {
  web: {
    client_id: ENV['CLIENT_ID'],
    project_id: ENV['PROJECT_ID'],
    auth_uri: ENV['AUTH_URI'],
    token_uri: ENV['TOKEN_URI'],
    auth_provider_x509_cert_url: ENV['CERT_URL'],
    client_secret: ENV['CLIENT_SECRETE'],
    redirect_uris: [ENV['REDIRECT_URI']]
  }
}
TOKEN_PATH = 'token.yaml'.freeze
SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

def authorize
  client_id = Google::Auth::ClientId.hash CREDENTIALS
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end


post '/callback' do
  request_body = JSON.parse(request.body.read)
  puts request_body
  case request_body['type']
  when 'url_verification'
    request_body['challenge']
  when 'event_callback'
    if request_body['event']['type'] == 'reaction_added'
      user = request_body['event']['user']
      channel = request_body['event']['item']['channel']
      ts = request_body['event']['item']['ts']
      announcement = Announcement.find_by(channel: channel, ts: ts)
      if announcement
        user_info_uri = URI('https://slack.com/api/users.info')
        user_info_params = {
          token: ENV['SLACK_API_TOKEN'],
          user: user
        }
        user_info_uri.query = URI.encode_www_form(user_info_params)
        user_info_res = Net::HTTP.get_response(user_info_uri)
        user_name_hash = JSON.parse(user_info_res.body)
        unless user_name_hash['user']['profile']['display_name'] == ''
          name = user_name_hash['user']['profile']['display_name']
        else
          name = user_name_hash['user']['profile']['real_name']
        end
        trainee = Trainee.find_by(slack_name: name)

        service = Google::Apis::SheetsV4::SheetsService.new
        service.client_options.application_name = APPLICATION_NAME
        service.authorization = authorize
        spreadsheet_id = ENV['SHEET_ID']
        range = "Sheet1!J10"
        response = service.get_spreadsheet_values(spreadsheet_id, range)
        puts response.to_json
      end
    elsif request_body['event']['channel'] == 'C012PCA7X1B' && request_body['event']['user'] != 'U012HRJKR6J'
      if request_body['event'].has_key?('text')
        message = request_body['event']['text']
        if message.include?('joined')
          user = request_body['event']['user']
          puts user
          user_info_uri = URI('https://slack.com/api/users.info')
          user_info_params = {
              token: ENV['SLACK_API_TOKEN'],
              user: user
            }
          user_info_uri.query = URI.encode_www_form(user_info_params)
          user_info_res = Net::HTTP.get_response(user_info_uri)
          user_name_hash = JSON.parse(user_info_res.body)
          user_name = user_name_hash['user']['real_name']
          return_text = "#{user_name}さんこんにちは！\nうぇびこの部屋へようこそ！"
          puts return_text
        else
          chat_params = {
            key: ENV['USER_LOCAL_TOKEN'],
            message: CGI.escape(message)
          }
          chat_uri = URI('https://chatbot-api.userlocal.jp/api/chat')
          chat_uri.query = URI.encode_www_form(chat_params)
          chat_res = Net::HTTP.get_response(chat_uri)
          return_hash = JSON.parse(chat_res.body)
          return_text = return_hash['result']
          puts return_text
        end
        slack_uri = URI('https://slack.com/api/chat.postMessage')
        slack_res = Net::HTTP.post_form(
          slack_uri,
          'token' => ENV['SLACK_API_TOKEN'],
          'channel' => '#times_webyko',
          'text' => return_text,
          'as_user' => true
        )
        puts slack_res.body
      end
      'ok'
    elsif request_body['event']['user'] != 'U012HRJKR6J' && request_body['event']['user'] != 'U012Q76K5T6'
      channel_info_uri = URI('https://slack.com/api/conversations.info')
      channel_params = {
        token: ENV['SLACK_API_TOKEN'],
        channel: request_body['event']['channel']
      }
      channel_info_uri.query = URI.encode_www_form(channel_params)
      channel_info_res = Net::HTTP.get_response(channel_info_uri)
      channel_info_hash = JSON.parse(channel_info_res.body)
      channel_name = channel_info_hash['channel']['name']
      puts channel_name
      if channel_name.include?('times')
        random = Random.new.rand
        puts random
        if random < 0.3
          Post.create(
            channel: request_body['event']['channel'],
            ts: request_body['event']['ts']
          )
        end
      end
      'ok'
    end
  end
  'ok'
end


post '/new_announcement' do
  puts request.body.read
  col = params[:col].to_i
  url = params[:url]
  name = params[:name]

  url = url.split('/')
  channel = url[4]
  ts = url[5].delete('p').split('').insert(10, '.').join('')

  Announcement.find_or_create_by(
    name: name,
    channel: channel,
    ts: ts,
    column: col
  )

  'ok'
end
