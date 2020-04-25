require 'bundler/setup'
require File.expand_path('server')

Faye::WebSocket.load_adapter('thin')
run DeviceControl::WebSocketServer.new(ENV)