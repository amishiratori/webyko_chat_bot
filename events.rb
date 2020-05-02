require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'json'
require 'date'
require 'time'
require 'dotenv'
require 'net/http'
require 'slack-ruby-client'

Dotenv.load

events_uri = URI('https://connpass.com/api/v1/event/')
date_now = Date.today()
year = date_now.year
month = date_now.month
if date_now.day > 25
  month += 1
end
if month < 10
  month = '0' + month.to_s
else
  month = month.to_s
end
events_params = {
  keyword_or: 'ruby,フロントエンド,サーバーサイド',
  ym: "#{year.to_s + month}"
}
events_uri.query = URI.encode_www_form(events_params)
events_res = Net::HTTP.get_response(events_uri)
events_hash = JSON.parse(events_res.body)

events_hash['events'].each_with_index do |event, i|
  tmp_time = Time.iso8601(event['started_at'])
  if tmp_time < Time.now()
    events_hash['events'].delete_at(i)
  end
end

random = Random.new()
rand_index = random.rand(events_hash['events'].length)
selected_event = events_hash['events'][rand_index]

start_time = Time.iso8601(selected_event['started_at'])
end_time = Time.iso8601(selected_event['ended_at'])
if start_time.month == end_time.month && start_time.day == end_time.day
  event_time = "#{start_time.month}月#{start_time.day}日　#{start_time.hour}:"
  if start_time.min < 10
    event_time << '0' + start_time.min.to_s + "~#{end_time.hour}:"
  else
    event_time << "#{start_time.min}~#{end_time.hour}:"
  end
  if end_time.min < 10
    event_time << '0' + end_time.min.to_s
  else
    event_time << "#{end_time.min}"
  end
else
  event_time = "#{start_time.month}月#{start_time.day}日　#{start_time.hour}:"
  if start_time.min < 10
    event_time << '0' + start_time.min.to_s
  else
    event_time << "#{start_time.min}"
  end
  event_time << "#{end_time.month}月#{end_time.day}日　#{end_time.hour}:"
  if end_time.min < 10
    event_time << '0' + end_time.min.to_s
  else
    event_time << "#{end_time.min}"
  end
end

return_text = "今日のおすすめイベントはこちら！\n"
return_text << "*#{selected_event['title']}*\n"
return_text << "#{selected_event['catch']}\n"
return_text << "#{event_time}\n"
return_text << selected_event['event_url']

puts return_text

slack_uri = URI('https://slack.com/api/chat.postMessage')
slack_res = Net::HTTP.post_form(
  slack_uri,
  'token' => ENV['SLACK_API_TOKEN'],
  'channel' => '#times_webyko',
  'text' => return_text,
  'as_user' => true
)
puts slack_res.body
'ok'