#!/usr/bin/env ruby
require "socket"
s = TCPSocket.open("localhost", 8000)
while line = s.gets
  puts "received : #{line.chop}"
end
s.close
