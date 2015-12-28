#!/usr/bin/env ruby

require 'socket'  
require 'thread'                
require 'open-uri'

class FileServer

  def initialize()
    @port = ARGV[0]        
    #@hostname = '0.0.0.0'
    @hostname = 'localhost'
    @fileServer = TCPServer.open(@hostname, @port)
    @ipaddress = open('http://whatismyip.akamai.com').read
    @workQ = Queue.new
    @pool_size = 5
    puts "Current pool size is #{@pool_size}"
    puts "Listening on: #{@hostname}:#{@port}"
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
        puts 'Thread pool full wait 5'
        sleep 5          
        client.close
      end
    end
  end

  def message_handler (client)
    loop do
      msg = client.gets
      puts msg
      
      # if kill request
      if msg.include?('KILL_SERVICE')  # if client writes KILL_SERVICE
        @fileServer.close
        exit
      
      # if HELO test
      elsif msg.include?('HELO')          # if client writes HELO text\n
        puts "HELO MESSAGE"
        client.puts msg + "IP:#{@ipaddress}\nPort:#{@port}\nStudentID:[66a55996468091b1f6f3b52e3181ccbcc584d5134ccb47e80c0797fed3ca9545]\n"
       
      # if create request
      elsif msg.include?('CREATE')
        filename = msg[/CREATE:(.*)$/,1]
        filename = filename.strip
        message = "FILENAME:#{filename}\nCOMMAND:w\n"
        file_handler(client, message)

      # if file request
      elsif msg.include?('FILENAME')
        msg += client.gets
        puts msg

        filename = msg[/FILENAME:(.*)$/,1]
        filename = filename.strip
        puts filename

        # check if file is on this server
        if File::exists?(filename)
          file_handler(client, msg)
        else
          client.puts "NOT FOUND\n"
        end

      # if string not recognised
      else
        client.puts "ERROR CODE: 001\nERROR DESCRIPTION: invalid string\n"
      end  

    end
  end

  def file_handler(client, msg)
    filename = msg[/FILENAME:(.*)$/,1]
    filename = filename.strip
    command = msg[/COMMAND:(.*)$/,1]
    command = command.strip

    # execute command
    if (command == "w" || command == "r")
      File.open(filename,command)

    elsif (command == "OPEN")
      File.open(filename)

    else
      File.close(filename)
    end

  end


end 


fileServerOne = FileServer.new
