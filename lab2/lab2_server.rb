require 'socket'                    # Get sockets from stdlib
require 'thread'                    # stdlib

class Server
  def initialize()
    @port = ARGV[0]                     # portnumber parameter
    @server = TCPServer.open(@port)     # open socket
    @ipaddress = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address #get IPAddress
    puts "Listening on port:[#{@port}]"
    startServer
  end

  def startServer
    loop do
      Thread.start(@server.accept) do |client|
        line = client.gets
        if line.include?('HELO')          # if client writes HELO text\n
          client.puts line + "IP:[#{@ipaddress}]\nPort:[#{@port}]\nStudentID:[x]\n"
        else
        if line.include?('KILL_SERVICE')  # if client writes KILL_SERVICE
          client.puts 'Exiting service...'
          Kernel.exit
        else
          client.puts('Thread going to sleep for 3s')
          sleep 3                          # to simulate thread in use
        end
        client.close                       # disconnect from client
        puts 'Disconnected from client'
    end
  end
end
end

server = Server.new
end
