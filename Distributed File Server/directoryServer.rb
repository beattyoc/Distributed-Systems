#!/usr/bin/env ruby

require 'socket'  
require 'thread'

class DirectoryServer

  def initialize()
    @port = 8003
    @directoryServer = TCPServer.open('localhost', @port)
    @fileServerOne = Hash.new
    @fileServerOne = {1=>"file1.txt", 2=>"file2.txt", 3=>"file3.txt"}
    @workQ = Queue.new
    @pool_size = 10
    puts "\nDirectory Server listening on: localhost:#{@port}"
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
      puts "Received: #{msg}"

      # if QUERY received
      if msg.include?('QUERY')
        filename = msg[/QUERY:(.*)$/,1]
        filename = filename.strip
        find_file(filename, proxy)
  
      else
        proxy.puts "ERROR: Uncrecognised request #{msg}"
      end
    end
  end

  def find_file(filename, proxy)
    @fileServerOne.each do |key, value|
      if (value == filename)
        puts "#{filename} found in directory one."
        proxy.puts "ONE:#{filename}"
        return
      end
    end
    return
  end

end 

directoryServer = DirectoryServer.new
