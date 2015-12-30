#!/usr/bin/env ruby

require 'socket'  
require 'thread' 

class ProxyServer

  def initialize()
    @fileServerPort = 8002
    @port = 8004
    @directoryServerPort = 8003
    @proxyServer = TCPServer.open('localhost', @port)
    @fileServer = TCPSocket.open('localhost', @fileServerPort)
    @directoryServer = TCPSocket.open('localhost', @directoryServerPort)
    @workQ = Queue.new
    @pool_size = 10
    puts "Client Proxy Server listening on: localhost:#{@port}"
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
        sleep 5          
        client.close
      end
    end
  end

  # handles the client
  def client_handler (client)
    loop do
      msg = client.gets
      puts "Received from client: #{msg}"

      # if kill request
      if msg.include?('KILL_SERVICE') 
        @fileServer.puts msg
        @fileServer.close
        @proxyServer.close
      
      # if HELO test
      elsif msg.include?('HELO')   
        @fileServer.puts msg
        fileserver_handler(client)

      # if an open request
      elsif msg.include?('OPEN')
        filename = msg[/OPEN:(.*)$/,1]
        filename = filename.strip
        @directoryServer.puts "QUERY:#{filename}"
        answer = @directoryServer.gets
        send_to_fileserver(client, answer, msg)

      # if a close request
      elsif msg.include?('CLOSE')
        filename = msg[/CLOSE:(.*)$/,1]
        filename = filename.strip
        @directoryServer.puts "QUERY:#{filename}"
        answer = @directoryServer.gets
        send_to_fileserver(client, answer, msg)

      # if a read request
      elsif msg.include?('READ')
        filename = msg[/READ:(.*)$/,1]
        filename = filename.strip
        @directoryServer.puts "QUERY:#{filename}"
        answer = @directoryServer.gets
        send_to_fileserver(client, answer, msg)

      # if a write request
      elsif msg.include?('WRITE')
        msg += client.gets
        filename = msg[/WRITE:(.*)$/,1]
        filename = filename.strip
        @directoryServer.puts "QUERY:#{filename}"
        answer = @directoryServer.gets
        send_to_fileserver(client, answer, msg)

      # if string not recognised
      else
        client.puts "ERROR: invalid string"
      end  
    end
  end

  # sends to correct fileserver
  def send_to_fileserver(client, answer, msg)
    if answer.include?('ONE')
      @fileServer.puts msg
      fileserver_handler(client, answer)
    elsif answer.include?('TWO')
      #@fileServerTwo.puts msg
      fileserver_handler(client, answer)
    else
      puts "Received #{answer}"
      client.puts "ERROR: File not found"
    end
    puts "returning"
    return
  end

  # handles socket connection with server one
  def fileserver_handler(client, answer)
    loop do
      if answer.include?('ONE')
        msg = @fileServer.gets
        client.puts msg
        puts "message: " + msg
        while(!msg.include?('END OF')) do
          msg = @fileServer.gets
          client.puts msg
        end
        client.puts "END OF FILE"
        return
      elsif answer.include?('TWO')
        #msg = @fileServerTwo.gets
        client.puts msg
      else
        return
      end
    end
  end

end 

proxyServer = ProxyServer.new
