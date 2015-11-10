#!/usr/bin/env ruby

require "socket"                      # get socket from stdlib

hostname = '127.0.0.1'
port = 8000
s = TCPSocket.open(hostname, port) # open socket

s.puts("HELO text\n")                  # writes string to socket

#s.puts("KILL_SERVICE\n")
#s.puts("random string")

while line = s.gets                   # read lines from sockets
  puts line.chop
end

s.close                               # close socket when done
