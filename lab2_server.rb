require "socket"
server = TCPServer.open(8000)
loop do
  Thread.fork(server.accept) do |client|
    client.puts("Hello, I'm Ruby TCP server", "I'm disconnecting, bye :*")
    client.close
end
end
