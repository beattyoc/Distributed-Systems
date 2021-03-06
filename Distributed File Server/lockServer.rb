#!/usr/bin/env ruby

require 'socket'  
require 'thread' 

class LockServer

  def initialize()
    @port = 8001
    @lockServer = TCPServer.open('localhost', @port)
    @workQ = Queue.new
    @pool_size = 10
    @Files = Hash.new
    @file1_lock = Mutex.new
    @file2_lock = Mutex.new
    @file3_lock = Mutex.new
    puts "\nLock Server listening on: localhost:#{@port}"
    run
  end

  # handles thread pooling and new connections
  def run
    loop do
      if @workQ.size < (@pool_size-1)
        Thread.start(@lockServer.accept) do | client |
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

  # handles client requests
  def message_handler (client)
    loop do
      msg = client.gets
      puts "Message from client: #{msg}"

      # if unlock request is made
      if msg.include?('UNLOCK')
        filename = msg[/UNLOCK:(.*$)/,1]
        filename = filename.strip
        puts "unlock request made on #{filename}"

        # if file1.txt
        if (filename.include?('file1'))
          if(@file1_lock.locked?)
            puts "Unlocking file1.txt"
            @file1_lock.unlock
            client.puts "OK: #{filename}"
          else
            client.puts "NO: #{filename}"
          end

        # if file2.txt
        elsif (filename.include?('file2'))
          if(@file2_lock.locked?)
            puts "Unlocking file2.txt"
            @file2_lock.unlock
            client.puts "OK: #{filename}"
          else
            client.puts "NO: #{filename}"
          end

        # if file3.txt
        elsif (filename.include?('file3'))
          if(@file3_lock.locked?)
            puts "Unlocking file3.txt"
            @file3_lock.unlock
            client.puts "OK: #{filename}"
          else
            client.puts "NO: #{filename}"
          end

        else
          client.puts "ERROR: Unkown filename #{filename}"
        end

      # if a lock request is made
      elsif msg.include?('LOCK')
        filename = msg[/LOCK:(.*)$/,1]
        filename = filename.strip
        puts "lock request made on #{filename}"

        # if file1.txt
        if (filename.include?('file1'))
          if(!@file1_lock.locked?)
            puts "Locking file1.txt"
            @file1_lock.lock
            client.puts "OK: #{filename}"
          else
            client.puts "NO: #{filename}"
          end

        # if file2.txt
        elsif (filename.include?('file2'))
          if(!@file2_lock.locked?)
            puts "Locking file2.txt"
            @file2_lock.lock
            client.puts "OK: #{filename}"
          else
            client.puts "NO: #{filename}"
          end

        # if file3.txt
        elsif (filename.include?('file3'))
          if(!@file3_lock.locked?)
            puts "Locking file3.txt"
            @file3_lock.lock
            client.puts "OK: #{filename}"
          else
            client.puts "NO: #{filename}"
          end

        else
          client.puts "ERROR: Unkown filename #{filename}"
        end

      else
        client.puts "ERROR: Can't recognise the request #{msg}"
      end
    end
  end

end 


lockServer = LockServer.new
