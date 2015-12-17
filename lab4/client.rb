#!/usr/bin/env ruby

require 'socket'                     # get socket from stdlib
require 'thread'
require 'open-uri'

class Client
	def initialize(server)
		@server = server
		@request = nil
		@response = nil
		send
		listen
		@request.join
		@response.join
		@client_name = "client1"
		@join_id = ""
		@room_ref = ""
		@server_ip = ""
		@port_num = ""
		@chatroom_name = ""
	end

	def listen
		@response = Thread.new do
			loop {
				msg = @server.gets
				puts "#{msg}"
				#if msg.include?('JOINED_CHATROOM')
				#	get_join_info(msg)
				#else
				#end
			}
		end
	end

	def send
		#puts 'Enter kill, join, leave or disconnect'
		@request = Thread.new do
			loop {
				msg = "JOIN_CHATROOM:room1\nCLIENT_IP:0\nPORT:0\nCLIENT_NAME:#{@client_name}\n"
				@server.puts(msg) 
				#sleep 3
				#msg = "LEAVE_CHATROOM:#{@room_ref}\nJOIN_ID:#{@join_id}\nCLIENT_NAME:#{@client_name}"
				#@server.puts(msg)
			}
		end
	end

	def get_join_info(msg)
		@chatroom_name = msg[/JOINED_CHATROOM:(.*)$/, 1]
		msg = client.gets
		@server_ip = msg[/SERVER_IP:(.*)$/, 1]
		msg = client.gets
		@port_num = msg[/PORT:(.*)$/, 1]
		msg = client.gets
		@room_ref = msg[/ROOM_REF:(.*)$/, 1]
		msg = client.gets
		@join_id = msg[/JOIN_ID:(.*)$/, 1]
	end


end


server = TCPSocket.open("localhost", 8000)
Client.new(server)
