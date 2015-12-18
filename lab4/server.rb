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
    @pool_size = 10
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
          msg = client.gets
          #puts "#{msg}"
          if msg.include?('KILL_SERVICE')  # if client writes KILL_SERVICE
            client.close
            Kernel.exit
          elsif msg.include?('HELO')          # if client writes HELO text\n
            client.puts msg + "\nIP:#{@ipaddress}\nPort:#{@port}\nStudentID:[66a55996468091b1f6f3b52e3181ccbcc584d5134ccb47e80c0797fed3ca9545]\n"
          elsif msg.include?('JOIN_CHATROOM')
            join_request(msg, client)
          else
            puts 'Thread going to sleep for 5s'
            sleep 5                          # to simulate thread in use
            client.close                       # disconnect from client
          end
          @workQ.pop(true)
        end
      end
    end
  end
  
  

  def listen_user_messages( client )
      loop do
          msg = client.gets
          if msg.include?('KILL_SERVICE')  # if client writes KILL_SERVICE
            client.close
            @server.close
            Kernel.exit
          elsif msg.include?('LEAVE_CHATROOM')
            leave_request(msg, client)
          elsif msg.include?('DISCONNECT')
            disconnect_request(msg, client)
          elsif msg.include?('JOIN_CHATROOM')
            join_request(msg, client)
          else msg.include?('CHAT')
              puts "message: #{msg}"
              puts "CHAT REQUEST"
              chat_request(msg,client)
          end
    end
  end



  def join_request(msg, client)

    chatroom_name = msg[/JOIN_CHATROOM:(.*)$/, 1]
    msg = client.gets
    client_ip = msg[/CLIENT_IP:(.*)/,1]
    msg = client.gets
    port_num = msg[/PORT:(.*)/,1]
    msg = client.gets
    client_name = msg[/CLIENT_NAME:(.*)$/, 1]
    
    puts "#{client_name} requests to join #{chatroom_name}"

    join_id = ""
    if @clients[client_name]
      join_id = @clients[client_name]
    else
      join_id = SecureRandom.uuid.gsub("-", "").hex
      @clients[client_name] = join_id
      @clients_by_id[join_id.to_s] = client
      puts "new client: #{@clients_by_id}"
    end

    room_ref = ""
    if @rooms[chatroom_name]
      room_ref = @rooms[chatroom_name]
    else
      room_ref = SecureRandom.uuid.gsub("-", "").hex
      @rooms[chatroom_name] = room_ref
      @rooms_by_id[room_ref.to_s] = chatroom_name
    end
 
    @memberships[room_ref.to_s].store "#{join_id.to_s}",1
    
    client.puts("JOINED_CHATROOM:#{chatroom_name}\nSERVER_IP:#{@ipaddress}\nPORT:#{port_num}\nROOM_REF:#{room_ref}\nJOIN_ID:#{join_id}\n")
    #client.puts("CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} has joined this chatroom.\n\n")
    message_room("CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} has joined this chatroom.\n\n", room_ref)
    
    listen_user_messages(client)
  end
  
  
  
  

  def leave_request(msg, client)
      
    room_ref = msg[/LEAVE_CHATROOM:(.*)$/, 1]
    msg = client.gets
    join_id = msg[/JOIN_ID:(.*)$/, 1]
    msg = client.gets
    client_name = msg[/CLIENT_NAME:(.*)$/, 1]
    
    puts "#{client_name.strip} requests to leave a chatroom #{@rooms_by_id[room_ref.strip]}"

    client.puts("LEFT_CHATROOM:#{room_ref}\nJOIN_ID:#{join_id}\n")
    #client.puts("CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} has left this chatroom.\n\n")
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
    
    listen_user_messages(client)
  end


  def chat_request(msg, client)
      
      puts "chat request: #{@clients_by_id}"
      
      room_ref = msg[/CHAT:(.*)$/, 1]
      msg = client.gets
      join_id = msg[/JOIN_ID:(.*)$/, 1]
      msg = client.gets
      client_name = msg[/CLIENT_NAME:(.*)$/, 1]
      msg = client.gets
      message = msg[/MESSAGE:(.*)$/, 1]
      
      puts "#{client_name.strip} to #{@rooms_by_id[room_ref.to_s.strip]}: #{message}"
      
      send_msg = "CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{message}"
      
      message_room(send_msg,room_ref)
      
      listen_user_messages(client)
      
  end


  def disconnect_request(msg, client)
      
      client_ip = msg[/DISCONNECT:(.*)$/, 1]
      msg = client.gets
      port_num = msg[/PORT:(.*)$/, 1]
      msg = client.gets
      client_name = msg[/CLIENT_NAME:(.*)$/, 1]
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
  
  
  

end

server = Server.new
