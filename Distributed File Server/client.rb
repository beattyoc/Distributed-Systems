#!/usr/bin/env ruby

require 'socket'

class Client

	def initialize()
		@proxyPort = 8004
		@proxy = TCPSocket.open('localhost', @proxyPort) # open socket
		run
	end

	def run
		loop do
			# get client command
			print "\nEnter a command 'OPEN', 'CLOSE', 'READ', or 'WRITE': "
			msg = STDIN.gets
			msg = msg.strip

			if msg.include?('KILL_SERIVCE')
				@proxy.puts msg

			elsif msg.include?('HELO')
				@proxy.puts msg

			elsif msg.include?('OPEN')
				print "\nEnter filename 'file1.txt', 'file2.txt' or 'file3.txt': "
				filename = STDIN.gets
				filename = filename.strip
				request = "OPEN:#{filename}\n"
				@proxy.puts request
				message_handler

			elsif msg.include?('CLOSE')
				print "\nEnter filename 'file1.txt', 'file2.txt' or 'file3.txt': "
				filename = STDIN.gets
				filename = filename.strip
				request = "CLOSE:#{filename}\n"
				@proxy.puts request
				message_handler

			elsif msg.include?('READ')
				print "\nEnter filename 'file1.txt', 'file2.txt' or 'file3.txt': "				
				filename = STDIN.gets
				filename = filename.strip
				request = "READ:#{filename}\n"
				@proxy.puts request
				message_handler

			elsif msg.include?('WRITE')
				print "\nEnter filename 'file1.txt', 'file2.txt' or 'file3.txt': "
				filename = STDIN.gets
				filename = filename.strip
				print "Enter message: "
				message = STDIN.gets
				message = message.strip
				request = "WRITE:#{filename}\nMESSAGE:#{message}"
				@proxy.puts request
				message_handler

			else 
				puts "\nERROR: Please enter 'KILL_SERVICE', 'HELO', 'READ' or ''WRITE'\n"
			end
		end
	end

	def message_handler
		loop do
			msg = @proxy.gets
			puts msg
			if msg.include?('END OF')
				return
			elsif msg.include?('ERROR')
				return
			end
		end
	end

end

client = Client.new