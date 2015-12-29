#!/usr/bin/env ruby

require 'socket'  
require 'thread'                
require 'open-uri'

class DirectoryServer

  def initialize()
    @port = ARGV[0]
    @serverOnePort = ARGV[1]   
    @hostname = 'localhost'
    @serverOneHostname = 'localhost'
    @directoryServer = TCPServer.open(@hostname, @port)
    @fileServerOne = TCPSocket.open(@serverOneHostname, @serverOnePort)
    @workQ = Queue.new
    @pool_size = 2
    @response = ""
    puts "Listening on: #{@hostname}:#{@port}"
    run
  end

  # handles thread pooling and new connections
  def run
    loop do
      if @workQ.size < (@pool_size-1)
        Thread.start(@directoryServer.accept) do | proxy |
          @workQ.push 1
          proxy_handler(proxy)
          @workQ.pop(true)
        end
      else
        # if thread pool is full
        sleep 5          
        proxy.close
      end
    end
  end

  def proxy_handler (proxy)
    loop do
      msg = proxy.gets
      puts msg
      if msg.include?('QUERY')
        msg = proxy.gets
        filename = msg[/FILENAME:(.*)$/,1]
        filename = filename.strip
        @fileServerOne.puts "QUERY:#{filename}\n"
        serverOne_handler(proxy, filename)
        
        # query 2 servers
      else
        proxy.puts "ERROR: not a query\n"
      end
    end
  end

  def serverOne_handler(proxy)
    loop do
      msg = @fileServerOne.gets
      if msg.include?('NOTFOUND')
        @response += "NOTFOUND: ONE\n"
      elsif msg.include?('FOUND')
        @response += "FOUND: ONE\n"
      else
        puts "ERROR: wrong string returned\n"
    end
  end

end 


directoryServer = DirectoryServer.new
