#!/usr/bin/env ruby

require 'socket'                    # Get sockets from stdlib
require 'thread'                    # stdlib
require 'open-uri'

class Server
  def initialize()
    @port = ARGV[0]                     # portnumber parameter
    @hostname = '0.0.0.0'
    @server = TCPServer.open(@hostname, @port)     # open socket
    #@ipaddress = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address #get IPAddress
    @ipaddress = open('http://whatismyip.akamai.com').read
    @workQ = Queue.new
    @pool_size = 10                      # for example there may be a max number of 5 threads
    puts "Current pool size is #{@pool_size}"
    puts "Listening on: #{@hostname}:#{@port}"
    theServer
  end

  def theServer
    loop do
      if @workQ.size < (@pool_size-1)
        Thread.start(@server.accept) do |client|
        #client.puts('Connection made')
        @workQ.push 1
        puts "#{@workQ.size} threads in use"
        line = client.gets
        if line.include?('HELO')          # if client writes HELO text\n
          client.puts line + "IP:#{@ipaddress}\nPort:#{@port}\nStudentID:[66a55996468091b1f6f3b52e3181ccbcc584d5134ccb47e80c0797fed3ca9545]\n"
          client.close
        elsif line.include?('KILL_SERVICE')  # if client writes KILL_SERVICE
          #client.puts 'Exiting service...'
          client.close
          Kernel.exit
        else
          puts 'Thread going to sleep for 5s'
          sleep 5                          # to simulate thread in use
          #client.puts('Disconnecting')
          client.close                       # disconnect from client
        end
        @workQ.pop(true)
      end   #end of thread
    else
      sleep 5                             #waiting for threads to free up
    end     #end of if @workQ
  end       #end of loop do
end         #end of method
end         #end of class

server = Server.new
