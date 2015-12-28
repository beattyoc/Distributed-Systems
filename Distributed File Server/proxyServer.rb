#!/usr/bin/env ruby

require 'socket'  
require 'thread'                
require 'open-uri'

class ProxyServer

  def initialize()
    @serverOnePort = ARGV[1]
    @port = ARGV[0]        
    #@hostname = '0.0.0.0'
    @hostname = 'localhost'
    @serverOneHostname = 'localhost'
    @proxyServer = TCPServer.open(@hostname, @port)
    @fileServerOne = TCPSocket.open(@serverOneHostname, @serverOnePort)
    @ipaddress = open('http://whatismyip.akamai.com').read
    @workQ = Queue.new
    @pool_size = 20
    puts "Current pool size is #{@pool_size}"
    puts "Listening on: #{@hostname}:#{@port}"
    run
  end

  # handles thread pooling and new connections
  def run
    loop do
      if @workQ.size < (@pool_size-1)
        Thread.start(@proxyServer.accept) do | client |
          @workQ.push 1
          client_handler(client)
          @workQ.pop(true)
        end
      else
        # if thread pool is full
        puts 'Thread pool full wait 5'
        sleep 5          
        client.close
      end
    end
  end

  # handles the client
  def client_handler (client)
    loop do
      msg = client.gets
      
      # if kill request
      if msg.include?('KILL_SERVICE') 
        @fileServerOne.puts msg
      
      # if HELO test
      elsif msg.include?('HELO')   
        @fileServerOne.puts msg
        fileserverOne_handler(client)

      # if create request
      elsif msg.include?('CREATE')
        @fileServerOne.puts msg
        fileserverOne_handler(client)

      # if a file request
      elsif msg.include?('FILENAME')
        # get filename
        filename = msg[/FILENAME:(.*)$/,1]
        filename = filename.strip

        # get command
        msg += client.gets
        command = msg[/COMMAND:(.*)$/,1]
        cmd = ""
        if command.include?('open')
          cmd = "OPEN"
        elsif command.include?('read')
          cmd = "r"
        elsif command.include?('write')
          cmd = "w"
        else
          cmd = "CLOSE"
        end

        # send string
        send_msg = "FILENAME:#{filename}\nCOMMAND:#{cmd}\n"
        @fileServerOne.puts send_msg
        fileserverOne_handler(client)
       
      # if string not recognised
      else
        client.puts "ERROR: invalid string\n"
      end  
    end
  end

  # handles socket connection with server one
  def fileserverOne_handler(client)
    loop do
      msgOne = @fileServerOne.gets
      puts "msgOne: #{msgOne}"
      client.puts "msgOne: #{msgOne}"

      # if query failed
      if msgOne.include?('NOT FOUND')
        puts "file not found in server one"
        #redirect to server 2

      # if error
      else
        puts "ERROR\n"
        client.puts "ERROR\n"
      end
    end
  end

end 

proxyServer = ProxyServer.new
