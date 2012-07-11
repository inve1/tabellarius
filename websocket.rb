require 'em-websocket'
require 'eventmachine'
require 'rest_client'
require 'json'

EventMachine.run {
    @channel = EM::Channel.new

    EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.onopen {
            sid = @channel.subscribe { |msg| ws.send msg }

            ws.onclose { @channel.unsubscribe(sid) }
            ws.onmessage { |msg|
                puts msg
                mess = JSON.parse(msg)
                num = mess['number']
                r = RestClient.post "http://127.0.0.1/messages/#{num}", {'text' => mess['text'] }
                puts r.code
                puts r.to_str

                @channel.push r.to_str
            }
        }
    end
}
