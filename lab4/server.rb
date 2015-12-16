#!/usr/bin/env ruby
require 'socket'
require 'thread'
require 'open-uri'

class Server
  def initialize()
    @port = ARGV[0]
    @hostname = '0.0.0.0'
    @server = TCPServer.open( @hostname, @port )
    @ipaddress = open('http://whatismyip.akamai.com').read
    @workQ = Queue.new
    @pool_size = 10
    @connections = Hash.new
    @rooms = Hash.new
    @clients = Hash.new
    @connections[:server] = @server
    @connections[:rooms] = @rooms
    @connections[:clients] = @clients
    puts "Current pool size is #{@pool_size}"
    puts "Listening on: #{@hostname}:#{@port}"
    run
  end

  def run
    loop do
      if @workQ.size < (@pool_size-1)
        Thread.start(@server.accept) do | client |
          @workQ.push 1
          msg = client.gets.chomp
          if msg.include?('HELO')          # if client writes HELO text\n
            client.puts msg + "IP:#{@ipaddress}\nPort:#{@port}\nStudentID:[66a55996468091b1f6f3b52e3181ccbcc584d5134ccb47e80c0797fed3ca9545]\n"
          elsif msg.include?('KILL_SERVICE')  # if client writes KILL_SERVICE
            puts 'KILL REQUEST'
            client.close
            Kernel.exit
          elsif msg.include?('JOIN_CHATROOM')
            puts 'JOIN REQUEST'
            #msg += client.gets.chomp + client.gets.chomp + client.gets.chomp
            join_request(msg, client)
          elsif msg.include?('LEAVE_CHATROOM')
            puts 'LEAVE REQUEST'
            leave_request(msg, client)
          elsif msg.include?('DISCONNECT')
            puts 'DISCONNECT REQUEST'
            disconnect_request(msg, client)
          else
            puts 'Thread going to sleep for 5s'
            sleep 5                          # to simulate thread in use
            client.close                       # disconnect from client
          end

          #nick_name = client.gets.chomp.to_sym
          #@connections[:clients].each do |other_name, other_client|
            #if nick_name == other_name || client == other_client
              #client.puts "This username already exist"
              #@workQ.pop(true)
              #Thread.kill self
            #end
          #end
          #puts "#{nick_name} #{client}"
          #@connections[:clients][nick_name] = client
          #client.puts "Connection established, Thank you for joining! Happy chatting"
          #listen_user_messages( nick_name, client )
          @workQ.pop(true)
        end
      end
    end
  end

  def listen_user_messages( username, client )
    puts "listen_user_messages"
    loop do
      msg = client.gets.chomp
      puts "#{username}: #{msg}"
      @connections[:clients].each do |other_name, other_client|
        unless other_name == username
          other_client.puts "#{username.to_s}: #{msg}"
        end
      end
    end
  end

  def join_request(msg, client)
    # Get arguments
    #puts "#{msg}"
    chatroom_name = msg[/JOIN_CHATROOM:(.*)$/, 1]
    msg = client.gets + client.gets
    msg = client.gets
    client_name = msg[/CLIENT_NAME:(.*)$/, 1]
    puts "#{client_name} requests to join #{chatroom_name}"
    @rooms = chatroom_name
  end

  def leave_request(msg, client)

  end

  def chat_request(msg, client)

  end

  def disconnect_request(msg, client)

  end

end

server = Server.new
