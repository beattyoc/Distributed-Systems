#!/usr/bin/env ruby

require 'socket'  
require 'thread'
require 'open-uri'

class FileServer

  def initialize()
    @port = 8002
    @replicaServerPort = 8000
    @lockServerPort = 8001
    @fileServer = TCPServer.open('localhost', @port)
    #@lockServer = TCPSocket.open('localhost', @lockServerPort)
    #@replicaServer = TCPSocket.open('localhost', @replicaServerPort)
    @ipaddress = open("https://wtfismyip.com/text").read
    @workQ = Queue.new
    @pool_size = 10
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
      puts "waiting..."
      msg = client.gets
      
      # if kill request
      if msg.include?('KILL_SERVICE')  # if client writes KILL_SERVICE
        @fileServer.close
        exit
      
      # if HELO test
      elsif msg.include?('HELO')          # if client writes HELO text\n
        puts "HELO MESSAGE"
        client.puts msg + "IP:#{@ipaddress}\nPort:#{@port}\nStudentID:[66a55996468091b1f6f3b52e3181ccbcc584d5134ccb47e80c0797fed3ca9545]\n"
       
      # if open request
      elsif msg.include?('OPEN')
        filename = msg[/OPEN:(.*)$/,1]
        open_request(client, filename.strip)

      # if close request
      elsif msg.include?('CLOSE')
        filename = msg[/CLOSE:(.*)$/,1]
        close_request(client, filename.strip)

      # if read request
      elsif msg.include?('READ')
        filename = msg[/READ:(.*)$/,1]
        read_request(client, filename.strip)

      # if write request
      elsif msg.include?('WRITE')
        msg += client.gets
        # create a back up
        #@replicaServer.puts msg
        filename = msg[/WRITE:(.*)$/,1]
        message = msg[/MESSAGE:(.*)$/,1]
        write_request(client, filename.strip, message.strip)

      # if string not recognised
      else
        client.puts "ERROR CODE: 001\nERROR DESCRIPTION: invalid string\n"
      end  

    end
  end

  # handles open requests from user
  def open_request(client, filename)
    return
  end

  # handles close requests from user
  def close_request(client, filename)
    return
  end

  # handles read requests from user
  def read_request(client, filename)
    aFile = File.open(filename, 'r')
    if aFile
      contents = File.read(filename)
      client.puts "\n\nCONTENTS OF #{filename}\n*****************\n\n#{contents}\n\n*****************\nEND OF #{filename}"
      #File.close(filename)
      puts "returning"
      return
    else
      client.puts "ERROR: Unable to open file #{filename}"
      return
    end
  end

  # handles write requests from user
  def write_request(client, filename, message)
    # obtain lock
    #lock_request = "LOCK:#{filename}"
    #@lockServer.puts lock_request
    #answer = @lockServer.gets
    #if(answer.include?('OK'))
      #puts "Obtained lock for #{filename}"
      aFile = File.open(filename, 'a+')
      if aFile
        File.write(filename, message)
        contents = File.read(filename)
        client.puts "\n\nCONTENTS OF #{filename}\n*****************\n\n#{contents}\n\n*****************\nEND OF #{filename}"
        #File.close(filename)
        # release lock
        #@lockServer.puts "UNLOCK:#{filename}"
        #puts "#{filename} unlocked"
        puts "returning"
        return
      else
        client.puts "ERROR: Unable to open file #{filename}"
        return
      end
    #else
     # puts "ERROR: #{filename} is already in use, please wait..."
      #write_again(client, filename, message)
    #end
  end

  # called if file was locked
  def write_again(client, filename, message)
    sleep 5
    write_request(client, filename, message)
  end

end 


fileServer = FileServer.new
