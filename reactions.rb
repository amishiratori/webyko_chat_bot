require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'dotenv'
require 'net/http'
require './models'

Dotenv.load

posts = Post.all
posts.each do |post|
  slack_uri = URI('https://slack.com/api/reactions.add')
  slack_res = Net::HTTP.post_form(
    slack_uri,
    'token' => ENV['SLACK_API_TOKEN'],
    'channel' => post.channel,
    'name' => 'webyko_clap',
    'timestamp' => post.ts
  )
  puts slack_res.body
end

Post.all.delete_all

'ok'