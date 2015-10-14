#!/usr/bin/env ruby
require "socket"
@port_num = ARGV[0]
server = TCPServer.open(@port_num)
loop do
  Thread.fork(server.accept) do |client|
    client.puts("Hello, I'm Ruby TCP server", "I'm disconnecting, bye :*")
    client.close
end
end
