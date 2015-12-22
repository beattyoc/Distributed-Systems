#!/usr/bin/env ruby
require 'socket'
require 'thread'
require 'open-uri'
require 'securerandom'

class Server
  def initialize()
    @port = ARGV[0]
    @hostname = '0.0.0.0'
    #@hostname = 'localhost'
    @server = TCPServer.open( @hostname, @port )
    @ipaddress = open('http://whatismyip.akamai.com').read
    @workQ = Queue.new
    @pool_size = 20
    @rooms = Hash.new
    @rooms_by_id = Hash.new
    @clients = Hash.new
    @clients_by_id = Hash.new
    @memberships = Hash.new{|hsh,key| hsh[key] = {} }
    puts "Current pool size is #{@pool_size}"
    puts "Listening on: #{@hostname}:#{@port}"
    run
  end

  def run
    loop do
      if @workQ.size < (@pool_size-1)
        Thread.start(@server.accept) do | client |
          @workQ.push 1
          listen_user_messages(client)
          @workQ.pop(true)
        end
      else
        puts 'Thread going to sleep for 5s'
        sleep 5                          # to simulate thread in use
        client.close
      end
    end
  end

  def listen_user_messages( client )
    loop do
      msg = client.gets
      if msg.include?('LEAVE_CHATROOM')
        msg += client.gets + client.gets
        leave_request(msg, client)
      elsif msg.include?('KILL_SERVICE')  # if client writes KILL_SERVICE
        kill_server
      elsif msg.include?('DISCONNECT')
        disconnect_request(msg, client)
      elsif msg.include?('HELO')          # if client writes HELO text\n
        client.puts msg + "IP:#{@ipaddress}\nPort:#{@port}\nStudentID:[66a55996468091b1f6f3b52e3181ccbcc584d5134ccb47e80c0797fed3ca9545]\n"
      elsif msg.include?('JOIN_CHATROOM')
        join_request(msg, client)
      elsif msg.include?('CHAT')
        chat_request(msg,client)
      else
        client.puts "ERROR CODE: 001\nERROR DESCRIPTION: invalid string\n"
      end
    end
  end

  def join_request(msg, client)
    msg += client.gets + client.gets + client.gets
    chatroom_name = msg[/JOIN_CHATROOM:(.*)$/, 1]
    client_ip = msg[/CLIENT_IP:(.*)/,1]
    port_num = msg[/PORT:(.*)/,1]
    client_name = msg[/CLIENT_NAME:(.*)$/, 1]
    puts "#{client_name} requests to join #{chatroom_name}"
    join_id = ""
    if @clients[client_name]
      join_id = @clients[client_name]
    else
      join_id = SecureRandom.random_number(50)
      @clients[client_name] = join_id
      @clients_by_id[join_id.to_s] = client
    end
    room_ref = ""
    if @rooms[chatroom_name]
      room_ref = @rooms[chatroom_name]
    else
      room_ref = SecureRandom.random_number(50)
      @rooms[chatroom_name] = room_ref
      @rooms_by_id[room_ref.to_s] = chatroom_name
    end
    @memberships[room_ref.to_s].store "#{join_id.to_s}",1
    client.puts("JOINED_CHATROOM:#{chatroom_name}\nSERVER_IP:#{@ipaddress}\nPORT:#{port_num}\nROOM_REF:#{room_ref}\nJOIN_ID:#{join_id}\n")
    message_room("CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} has joined this chatroom.\n\n", room_ref)
  end

  def leave_request(msg, client)
    room_ref = msg[/LEAVE_CHATROOM:(.*)$/, 1]
    join_id = msg[/JOIN_ID:(.*)$/, 1]
    client_name = msg[/CLIENT_NAME:(.*)$/, 1]
    puts "#{client_name.strip} requests to leave a chatroom #{@rooms_by_id[room_ref.strip]}"
    client.puts("LEFT_CHATROOM:#{room_ref}\nJOIN_ID:#{join_id}\n")
    message_room("CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} has left this chatroom.\n\n", room_ref)
    @memberships.each do |rr, ji|
      if (rr.strip == room_ref.strip)
        @memberships[rr].each do |members,value|
          if (members.to_s.strip == join_id.to_s.strip)
            @memberships[rr.strip].delete(members)
          end
        end
      end
    end
  end

  def chat_request(msg, client)
    msg += client.gets + client.gets + client.gets + client.gets
    room_ref = msg[/CHAT:(.*)$/, 1]
    join_id = msg[/JOIN_ID:(.*)$/, 1]
    client_name = msg[/CLIENT_NAME:(.*)$/, 1]
    message = msg[/MESSAGE:(.*)$/, 1]
    puts "#{client_name.strip} to #{@rooms_by_id[room_ref.to_s.strip]}: #{message}"
    send_msg = "CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{message}\n\n"
    message_room(send_msg,room_ref)
  end

  def disconnect_request(msg, client)
    client_ip = msg[/DISCONNECT:(.*)$/, 1]
    msg = client.gets
    port_num = msg[/PORT:(.*)$/, 1]
    msg = client.gets
    client_name = msg[/CLIENT_NAME:(.*)$/, 1]
    puts "#{client_name} requests to disconnect"
    join_id = @clients[client_name]
    @memberships.each do |rr, ji|
      @memberships[rr].each do |members, values|
        if(members.to_s.strip == join_id.to_s.strip)
          @memberships[rr.strip].delete(members)
          send_msg = "CHAT:#{rr}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} is disconnecting\n\n"
          client.puts send_msg
          message_room(send_msg, rr)
        end
      end
    end
    @clients.delete(client_name)
    @clients_by_id.delete(join_id)
    client.close
  end

  def message_room(msg,room_ref)
    @memberships.each do |rr, ji|
      if(rr.to_s.strip == room_ref.to_s.strip)
        @memberships[rr].each do |members,value|
          @clients_by_id[members].puts msg
        end
      end
    end
  end

  def kill_server
    @server.close
    exit
  end

end

server = Server.new
