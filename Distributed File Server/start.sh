#!/bin/bash
ruby fileServerOne.rb $1
ruby proxyServer.rb $2 $1
