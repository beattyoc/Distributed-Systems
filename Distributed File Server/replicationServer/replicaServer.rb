#!/usr/bin/env ruby

require 'socket'  
require 'thread'                
require 'open-uri'

class ReplicaServer

  def initialize()
    @port = 8000
    @hostname = 'localhost'
    @replicaServer = TCPServer.open(@hostname, @port)
    @workQ = Queue.new
    @pool_size = 10
    puts "\nReplication Server listening on: localhost:#{@port}"
    run
  end

  # handles thread pooling and new connections
  def run
    loop do
      #Kernel.exit
      if @workQ.size < (@pool_size-1)
        Thread.start(@replicaServer.accept) do | client |
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

      if msg.include?('WRITE')
        msg += client.gets
        filename = msg[/WRITE:(.*)$/,1]
        message = msg[/MESSAGE:(.*)$/,1]
        backup_request(client, filename.strip, message.strip)

      # if string not recognised
      else
        client.puts "ERROR CODE: 001\nERROR DESCRIPTION: invalid string\n"
      end  

    end
  end

  # backs up updated files
  def backup_request(client, filename, message)
    filename = "BACKUP_#{filename}"
    aFile = File.open(filename, 'w+')
    if aFile
      File.write(filename, message)
      puts "Updated: #{filename}"
    else
      client.puts "ERROR: Unable to open file #{filename}"
    end
    aFile.close
    return
  end


end 


replicaServer = ReplicaServer.new
