require 'json'
require 'net/http'
require 'uri'
require 'rest_client'
require 'sinatra'
require 'sinatra/config_file'


config_file 'settings.yml'
couch = RestClient::Resource.new("http://#{settings.couchhost}:#{settings.couchport}")

get '/users/' do
    users = couch['users/_design/namenumber/_view/name_number/'].get
    us = JSON.parse(users)['rows']
    for item in us do
        item.delete('id')
    end
    us.to_json
end


get '/messages/:number' do |num|
    resp = couch['messages/_design/query/_view/mess_fromto'].get 'key' => "%22#{num}%22"
    mess = JSON.parse(resp)['rows']
    return mess[-settings.messlimit, settings.messlimit].to_json
end


post '/messages/:number' do |num|
    tosend = { 'fromto' => num, 'is_sent' => true, 'date' => Time.now.to_i, 'text' => params[:text] }
    couch['/messages/'].post tosend.to_json , :content_type => :json, :accept => :json
    return {'value' => tosend}.to_json
end
