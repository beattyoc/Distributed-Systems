#DISTRIBUTED FILE SERVER

*Project written in ruby*

All servers are defaulted to run on 'localhost' from ports 8000 to 8004

##Please run in order: 
1. ./replicaServer.rb
2. ./lockServer.rb
3. ./fileServer.rb
4. ./directoryServer.rb
5. ./proxyServer.rb
6. ./client.rb

###*You may also try ./start.sh which starts all servers in 1 terminal window, and then ./client.rb in a separate terminal window for best user interface.*

##Project Components:
-Distributed Transparent File Access
-Directory Service
-Lock Service
-Replication
