#!/usr/bin/env ruby

require 'socket'  
require 'thread'                
require 'open-uri'

class FileServer

  def initialize()
    @port = 8001
    @replicaServerPort = 8000
    @fileServer = TCPServer.open('localhost', @port)
    @replicaServer = TCPSocket.open('localhost', @replicaServerPort)
    @ipaddress = open('http://whatismyip.akamai.com').read
    @workQ = Queue.new
    @pool_size = 4
    @Files = Hash.new
    puts "File Server listening on: localhost:#{@port}"
    run
  end

  # handles thread pooling and new connections
  def run
    loop do
      #Kernel.exit
      if @workQ.size < (@pool_size-1)
        Thread.start(@fileServer.accept) do | client |
          @workQ.push 1
          message_handler(client)
          @workQ.pop(true)
        end
      else
        # if thread pool is full
        sleep 5          
        client.close
      end
    end
  end

  def message_handler (client)
    loop do
      msg = client.gets
      puts "client request: #{msg}"
      
      # if kill request
      if msg.include?('KILL_SERVICE')  # if client writes KILL_SERVICE
        @fileServer.close
        exit
      
      # if HELO test
      elsif msg.include?('HELO')          # if client writes HELO text\n
        puts "HELO MESSAGE"
        client.puts msg + "IP:#{@ipaddress}\nPort:#{@port}\nStudentID:[66a55996468091b1f6f3b52e3181ccbcc584d5134ccb47e80c0797fed3ca9545]\n"
       
      # if read request
      elsif msg.include?('READ')
        filename = msg[/READ:(.*)$/,1]
        read_request(client, filename.strip)

      # if write request
      elsif msg.include?('WRITE')
        msg += client.gets
        puts "GOT MESSAGE: #{msg}"
        @replicaServer.puts msg
        filename = msg[/WRITE:(.*)$/,1]
        message = msg[/MESSAGE:(.*)$/,1]
        write_request(client, filename.strip, message.strip)

      # if string not recognised
      else
        client.puts "ERROR CODE: 001\nERROR DESCRIPTION: invalid string\n"
      end  

    end
  end

  # handles read requests from user
  def read_request(client, filename)
    aFile = File.open(filename, 'r')
    if aFile
      contents = File.read(filename)
      puts contents
      client.puts "\n\nCONTENTS OF #{filename}\n*****************\n\n#{contents}\n\n*****************\nEND OF #{filename}"
      File.close(filename)
    else
      client.puts "ERROR: Unable to open file #{filename}"
    end
  end

  # handles write requests from user
  def write_request(client, filename, message)
    puts "writing"
    aFile = File.open(filename, 'w+')
    if aFile
      File.write(filename, message)
      contents = File.read(filename)
      client.puts "\n\nCONTENTS OF #{filename}\n*****************\n\n#{contents}\n\n*****************\nEND OF #{filename}"
      File.close(filename)
    else
      client.puts "ERROR: Unable to open file #{filename}"
    end
  end


end 


fileServer = FileServer.new
