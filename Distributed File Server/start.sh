#!/bin/bash
ruby ./replicationServer/replicaServer.rb &
ruby ./lockServer.rb &
ruby ./fileServer/fileServer.rb &
ruby ./directoryServer.rb &
ruby ./proxyServer.rb #&
#ruby ./client.rb