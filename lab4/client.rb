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
	end

	def listen
		@response = Thread.new do
			loop {
				msg = @server.gets.chomp
				puts "#{msg}"
			}
		end
	end

	def send
		#puts 'Enter kill, join, leave or disconnect'
		@request = Thread.new do
			loop {
				msg = "JOIN_CHATROOM: chat001\nCLIENT_IP: 0\nPORT: 0\nCLIENT_NAME: user1\n"
				@server.puts(msg) 
			}
		end
	end
end

server = TCPSocket.open("localhost", 8000)
Client.new(server)
