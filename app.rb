# frozen_string_literal: true

require 'apnotic'
require 'base64'
require 'sinatra'

require 'dotenv/load' if ENV['RACK_ENV'] == 'development'

Warning[:deprecated] = false # remove when http-2 gem is updated

CONNECTION_OPTIONS = {
  auth_method: :token,
  cert_path: StringIO.new(ENV['APNS_AUTH_KEY']),
  key_id: ENV['APNS_KEY_ID'],
  team_id: ENV['APPLE_TEAM_ID']
}.freeze

SANDBOX_CONNECTION = Apnotic::Connection.development(CONNECTION_OPTIONS.dup)

SANDBOX_CONNECTION.on(:error) { |e| puts "Connection error (sandbox): #{e}" }

CONNECTION_POOL =
  Apnotic::ConnectionPool.new(
    CONNECTION_OPTIONS.dup,
    size: ENV['CONNECTION_POOL_SIZE'].to_i
  ) do |connection|
    connection.on(:error) { |e| puts "Connection error: #{e}" }
  end

get '/' do
  200
end

post '/push/:device_token/:id' do
  request.body.rewind

  notification = Apnotic::Notification.new(params[:device_token])

  notification.topic = ENV['TOPIC']
  notification.alert = Base64.urlsafe_encode64(request.body.read)
  notification.mutable_content = true
  notification.custom_payload = {
    i: params[:id],
    s: request.env['HTTP_ENCRYPTION'].split('salt=').last,
    k: request.env['HTTP_CRYPTO_KEY'].split('dh=').last.split(';').first
  }

  if params[:sandbox] == 'true'
    push = SANDBOX_CONNECTION.prepare_push(notification)

    push.on(:response) { |r| puts "Bad response (sandbox): #{r.inspect}" unless r.ok? }

    SANDBOX_CONNECTION.push_async(push)
  else
    CONNECTION_POOL.with do |connection|
      push = connection.prepare_push(notification)

      push.on(:response) { |r| puts "Bad response: #{r.inspect}" unless r.ok? }

      connection.push_async(push)
    end
  end

  202
end
