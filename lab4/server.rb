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
    @memberships = Hash.new
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
            puts 'KILL REQUEST'
            client.close
            Kernel.exit
          elsif msg.include?('HELO')          # if client writes HELO text\n
            client.puts msg + "\nIP:#{@ipaddress}\nPort:#{@port}\nStudentID:[66a55996468091b1f6f3b52e3181ccbcc584d5134ccb47e80c0797fed3ca9545]\n"
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
      loop do
          msg = client.gets
          #puts "#{username}: #{msg}"
          if msg.include?('KILL_SERVICE')  # if client writes KILL_SERVIC
            puts 'KILL REQUEST'
            client.close
            @server.close
            Kernel.exit
          elsif msg.include?('LEAVE_CHATROOM')
            puts 'LEAVE REQUEST'
            leave_request(msg, client)
          elsif msg.include?('DISCONNECT')
            puts 'DISCONNECT'
            disconnect_request(msg, client)
          elsif msg.include?('JOIN_CHATROOM')
            puts 'JOIN REQUEST'
            join_request(msg, client)
          else
          end
      #@connections[:clients].each do |other_name, other_client|
       # unless other_name == username
        #  other_client.puts "#{username.to_s}: #{msg}"
        #end
      #end
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

    join_id = ""
    if @clients[client_name]
      puts 'Repeat client'
      join_id = @clients[client_name]
      @clients_by_id[join_id] = client
    else
      join_id = SecureRandom.uuid.gsub("-", "").hex
      @clients[client_name] = join_id
      @clients_by_id[join_id] = client
    end

    room_ref = ""
    if @rooms[chatroom_name]
      puts 'Repeat room'
      room_ref = @rooms[chatroom_name]
      @rooms_by_id[room_ref] = chatroom_name
    else
      #room_ref = SecureRandom.uuid.gsub("-", "").hex
      room_ref = SecureRandom.random_number(1000)
      puts room_ref
      @rooms[chatroom_name] = room_ref
      @rooms_by_id[room_ref] = chatroom_name
    end
 
    @memberships[room_ref] = join_id
    
    client.puts("JOINED_CHATROOM:#{chatroom_name}\nSERVER_IP:#{@ipaddress}\nPORT:#{port_num}\nROOM_REF:#{room_ref}\nJOIN_ID:#{join_id}\n")
    #client.puts("CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} has joined this chatroom.\n\n")
    message_room("CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} has joined this chatroom.\n\n", room_ref)
    listen_user_messages(client_name,client)
  end
  
  
  
  

  def leave_request(msg, client)
      
    room_ref = msg[/LEAVE_CHATROOM:(.*)$/, 1]
    #puts room_ref
    msg = client.gets
    join_id = msg[/JOIN_ID:(.*)$/, 1]
    msg = client.gets
    client_name = msg[/CLIENT_NAME:(.*)$/, 1]

    #leave
    #puts @rooms_by_id

    client.puts("LEFT_CHATROOM:#{room_ref}\nJOIN_ID:#{join_id}\n")
    client.puts("CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} has left this chatroom.\n\n")
    #message_room("CHAT:#{room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} has left this chatroom.\n\n", room_ref)
    listen_user_messages(client_name,client)
  end



  def chat_request(msg, client)

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
        #if(rr.eql?(room_ref))
        if(rr == room_ref)
            puts "rr matches"
            @clients_by_id[ji].puts msg
        else
            puts "no match"
        end
    end
  end
  
  
  

end

server = Server.new
