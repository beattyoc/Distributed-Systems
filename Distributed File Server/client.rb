#!/usr/bin/env ruby

require 'socket'

class Client

	def initialize()
		@proxyPort = 8000
		@proxyHostname = 'localhost'
		@proxy = TCPSocket.open(@proxyHostname, @proxyPort) # open socket
		run
	end

	def run
		loop do
			# get client command
			print "Enter a command: "
			cmd = STDIN.gets
			cmd = cmd.strip

			if cmd.include?('kill')
				puts cmd
				@proxy.puts "KILL_SERVICE\n"

			elsif cmd.include?('helo')
				@proxy.puts "HELO base test\n"

			elsif cmd.include?('create')
				print "Enter filename: "
				filename = STDIN.gets
				filename = filename.strip
				send_msg = "CREATE: #{filename}\n"
				@proxy.puts send_msg
				message_handler

			elsif cmd.include?('open' || 'close' || 'read' || 'write')
				print "Enter filename: "
				filename = STDIN.gets
				filename = filename.strip
				send_msg = "FILENAME:#{filename}\nCOMMAND:#{cmd}\n"
				@proxy.puts send_msg
				puts send_msg
				message_handler

			else 
				puts "Unknown string please enter 'kill', 'helo', 'open', 'close', 'read', 'create' or 'write'"
			end
		end
	end

	def message_handler
		loop do
			msg = @proxy.gets
			puts msg
		end
	end

end

client = Client.new