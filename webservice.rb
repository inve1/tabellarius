require 'json'
require 'em-websocket'
require 'eventmachine'
require 'net/http'
require 'uri'
require 'rest_client'
require 'sinatra/base'
require 'sinatra/config_file'
require 'thin'

EventMachine.run do

    class Tabellarius < Sinatra::Base
        register Sinatra::ConfigFile
        config_file 'settings.yml'
        @@channel = EM::Channel.new

        def self.channel
            @@channel
        end

        @@couch = RestClient::Resource.new("http://#{settings.couchhost}:#{settings.couchport}")

        get '/users/' do
            users = @@couch['users/_design/namenumber/_view/name_number/'].get
            us = JSON.parse(users)['rows']
            for item in us do
                item.delete('id')
            end
            us.to_json
        end


        get '/messages/:number' do |num|
            resp = @@couch['messages/_design/query/_view/mess_fromto'].get 'key' => "%22#{num}%22"
            puts resp.to_str
            mess = JSON.parse(resp)['rows']
            return mess.to_json
        end
        
        def self.add_message(number, text)
            tosend = { 'fromto' => number, 'is_sent' => true, 'date' => Time.now.to_i, 'text' => text }
            @@couch['/messages/'].post tosend.to_json , :content_type => :json, :accept => :json
            @@channel.push({'value' => tosend}.to_json)
        end

        post %r{/messages/(\w+)} do |num|
            Tabellarius.add_message(num, params[:text])
        end

        post %r{/messages/\+(\d+)} do |num|
            users = @@couch['users/_design/query/_view/number_id/'].get 'key' => "%22#{num}%22"
            us = JSON.parse(users)['rows'][0]['value']
            Tabellarius.add_message(us, params[:text])
        end
    end


    EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.onopen {
            sid = Tabellarius.channel.subscribe { |msg| ws.send msg }
            puts 'asd'

            ws.onclose { Tabellarius.channel.unsubscribe(sid) }
            ws.onmessage { |msg|
                mess = JSON.parse(msg)
                num = mess['number']
                Tabellarius.add_message(num, mess['text'])
            }
        }
    end
    puts 'bella!'
    Thin::Server.start Tabellarius, '0.0.0.0', 4567
end
