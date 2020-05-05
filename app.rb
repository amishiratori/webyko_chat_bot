require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'json'
require 'dotenv'
require 'net/http'
require 'slack-ruby-client'
require 'google/apis/sheets_v4'
require './models'

Dotenv.load

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
        puts name
        trainee = Trainee.find_by(slack_name: name)

        service = Google::Apis::SheetsV4::SheetsService.new
        service.key = ENV['GOOGLE_API_KEY']
        sheet_id = ENV['SHEET_ID']
        range = 'J10'
        response = service.get_spreadsheet_values(sheet_id, range)
        response.values.each do |row|
          puts row
        end
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
