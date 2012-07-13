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
            resp = @@couch["messages/_design/query/_view/mess_fromto?key=%22#{num}%22"].get
            mess = JSON.parse(resp)['rows']
            return mess.to_json
        end
        
        def self.add_message(number, text, is_sent)
            tosend = { 'fromto' => number, 'is_sent' => is_sent, 'date' => Time.now.to_i, 'text' => text }
            @@couch['/messages/'].post tosend.to_json , :content_type => :json, :accept => :json
            @@channel.push({'message' => {'value' => tosend}}.to_json)
        end

        post %r{/messages/(\w+)} do |num|
            Tabellarius.add_message(num, params[:text], true)
        end

        post %r{/messages/\+(\d+)} do |num|
            users = @@couch["users/_design/query/_view/number_id?key=%22#{num}%22"].get

            parsed =  JSON.parse(users)
            if parsed['rows'] == []
                id = Tabellarius.add_user('Unknown', num)
            else
                id = parsed['rows'][0]['value']
            end
            Tabellarius.add_message(id, params[:text], false)
            return ""
        end

       def self.add_user(name, num)
            new_user = { 'name' => name, 'number' => num }
            resp = @@couch['/users/'].post new_user.to_json , :content_type => :json, :accept => :json
            parsed_resp = JSON.parse(resp)
            to_send = {'user' => { 'key' => parsed_resp['id'], 'value' => new_user}}
            @@channel.push(to_send.to_json)
            return parsed_resp['id']
        end

        post %r{/users/(\w+)/\+(\w+)} do |name, num|
            Tabellarius.add_user(name, num)
            return ""
        end


    end


    EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.onopen {
            sid = Tabellarius.channel.subscribe { |msg| ws.send msg }

            ws.onclose { Tabellarius.channel.unsubscribe(sid) }
            ws.onmessage { |msg|
                puts msg
                mess = JSON.parse(msg)
                num = mess['number']
                Tabellarius.add_message(num, mess['text'], true)
            }
        }
    end
    puts 'bella!'
    Thin::Server.start Tabellarius, '0.0.0.0', 4567
end
