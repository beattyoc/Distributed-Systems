require "socket"                      # get socket from stdlib

s = TCPSocket.open("localhost", 8000) # open socket

#s.puts("HELO text\n")                  # writes string to socket

s.puts("KILL_SERVICE\n")

while line = s.gets                   # read lines from sockets
  puts line.chop
end

s.close                               # close socket when done
