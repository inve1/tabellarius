require 'json'
require 'net/http'
require 'uri'

require 'rest_client'

# myapp.rb
require 'sinatra'

get '/nigr' do
  'Hello nig!'
end

get '/users/' do
    uri = URI.parse('http://127.0.0.1:5984/users/_design/namenumber/_view/name_number/')
    users = Net::HTTP.get(uri)
    us = JSON.parse(users)['rows']
    for item in us do
        item.delete('id')
    end
    us.to_json
end


get '/messages/:number' do |num|
    uri = URI.parse("http://127.0.0.1:5984/messages/_design/query/_view/mess_fromto?key=%22#{num}%22")
    resp = Net::HTTP.get(uri)
    mess = JSON.parse(resp)['rows']
    return mess.to_json
end


post '/messages/:number' do |num|
    tosend = { 'fromto' => num, 'is_sent' => true, 'date' => Time.now.to_i, 'text' => params[:text] }
    RestClient.post "http://127.0.0.1:5984/messages/", tosend.to_json , :content_type => :json, :accept => :json
    return {'value' => tosend}.to_json
end
