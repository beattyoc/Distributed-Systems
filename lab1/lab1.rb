require 'socket'      # Sockets are in standard library

request = "GET /echo.php?message=abcd HTTP/1.0\r\n\r\n"


s = TCPSocket.open('localhost', 8000)

  s.print(request)    #send request
  response = s.read   #read complete response

  puts response

s.close               # Close the socket when done
