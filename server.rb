require 'faye/websocket'
require File.expand_path('utility')
require 'json'

module DeviceControl
  class WebSocketServer

    KEEPALIVE_TIME = 15 # sec

    FORBIDDEN = "forbidden"

    CONNECT_REQUEST = "connect_request"
    CONNECT_RESPONSE = "connect_response"

    CONNECTED_DEVICES_REQUEST = "get_connected_devices_request"
    CONNECTED_DEVICES_RESPONSE = "get_connected_devices_response"

    DEVICE_GET_CONTACTS_REQUEST = "get_contacts_request"
    DEVICE_GET_CONTACTS_RESPONSE = "get_contacts_response"

    DEVICE_GET_CALL_HISTORY_REQUEST = "get_call_history_request"
    DEVICE_GET_CALL_HISTORY_RESPONSE = "get_call_history_response"

    DEVICE_GET_LOCATION_REQUEST = "get_location_request"
    DEVICE_GET_LOCATION_RESPONSE = "get_location_response"

    DEVICE_TAKE_PHOTO_REQUEST = "take_photo_request"
    DEVICE_TAKE_PHOTO_RESPONSE = "take_photo_response"

    DEVICE_RECORD_VIDEO_REQUEST = "record_video_request"
    DEVICE_RECORD_VIDEO_RESPONSE = "record_video_response"

    def initialize(app)
      @app = app
      @clients = []
      @session = WSUtility::Session.new
    end


    def call(env)

      if Faye::WebSocket.websocket?(env) then
        ws = Faye::WebSocket.new(env, nil, { :ping => KEEPALIVE_TIME })
        ws.on :open do |event|
          p [:open, @app]
          @clients << ws
          webSocketClient = WebSocketClient.new
          webSocketClient.id = ws.object_id
          @session.add(ws.object_id, webSocketClient)
        end

        ws.on :message do |event|
          @current_client = ws
          if event.data.is_a? String then
            @json = JSON.parse(event.data)
          else
            @json = JSON.parse(event.data.pack('c*')) 
          end

          client_type = @json['client_info']['type']
          identifier = @json['identifier']

          if client_type == 'browser' then
            user_id = @session.authenticate(identifier)
            if !user_id.nil? then
              process_browser_incoming_message(user_id)            
            else
              forbidden_result(FORBIDDEN)
            end

          elsif client_type == 'ios' then
            device_id = @session.authenticate(identifier)
            if !device_id.nil? then
              process_device_incoming_message(device_id)        
            else
              forbidden_result(FORBIDDEN)
            end
          end

        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]
          @session.remove(ws.object_id)
          @clients.delete(ws)
          ws = nil
        end

        ws.rack_response # return async rack response
      else
        @app.call(env)
      end

    end

    #---------------------------------------------------------------------------------------------| BROWSER CLIENT |----------------------

    def process_browser_incoming_message(user_id)
      command_name = @json['command']['name']
      p command_name
      case command_name
        when CONNECT_REQUEST then
          process_browser_connect_request(user_id)
        when DEVICE_GET_CONTACTS_REQUEST then
          process_browser_device_get_contacts_request(user_id)
        when DEVICE_GET_CALL_HISTORY_REQUEST then
          process_browser_device_get_call_history_request(user_id)
        when DEVICE_GET_LOCATION_REQUEST then
          process_browser_device_get_location_request(user_id)
        when DEVICE_TAKE_PHOTO_REQUEST then
          process_browser_device_take_photo_request(user_id)
        when DEVICE_RECORD_VIDEO_REQUEST then
          process_browser_device_record_video_request(user_id)
      end
    end


    def process_browser_connect_request(user_id)
      @session.set(@current_client.object_id, "browser", user_id)
      success_result(CONNECT_RESPONSE)
    end


    def process_browser_device_get_contacts_request(user_id)
      if @session.authenticated? user_id then
        device_id = @json['command_parameters']['device_id'].to_i
        device_client_info = @session.get_device_info(device_id)

        if !device_client_info.nil? then
          device_client = @clients.select { |client| client.object_id == device_client_info.id }.first

          if !@evice_client.nil? then
            device_client.send({
              :command => {
                :name => DEVICE_GET_CONTACTS_REQUEST
              },
              :command_parameters => {
                :request_user_id => user_id
              }
            }.to_json)

          end
        end
      end
    end


    def process_browser_device_get_call_history_request(user_id)

      if @session.authenticated? user_id then
        device_id = @json['command_parameters']['device_id'].to_i
        device_client_info = @session.get_device_info(device_id)

        if !device_client_info.nil? then
          device_client = @clients.select {|client| client.object_id == device_client_info.id }.first

          if !device_client.nil? then
            device_client.send({
              :command => {
                :name => DEVICE_GET_CALL_HISTORY_REQUEST
              },
              :command_parameters => {
                :request_user_id => user_id
              }
            }.to_json)

          end
        end
      end
    end


    def process_browser_device_get_location_request(user_id)

      if @session.authenticated? user_id then
        device_id = @json['command_parameters']['device_id'].to_i
        device_client_info = @session.get_device_info(device_id)

        if !device_client_info.nil? then
          device_client = @clients.select{|client| client.object_id == device_client_info.id}.first

          if !device_client.nil? then
            device_client.send({
              :command => {
                :name => DEVICE_GET_LOCATION_REQUEST
              },
              :command_parameters => {
                :request_user_id => user_id
              }
            }.to_json)

          end
        end
      end
    end


    def process_browser_device_take_photo_request(user_id)

      if @session.authenticated? user_id then
        device_id = @json['command_parameters']['device_id'].to_i
        device_client_info = @session.get_device_info(device_id)

        if !device_client_info.nil? then
          device_client = @clients.select{|client| client.object_id == device_client_info.id}.first

          if !device_client.nil? then
            device_client.send({
              :command => {
                :name => DEVICE_TAKE_PHOTO_REQUEST
              },
              :command_parameters => {
                :request_user_id => user_id
              }
            }.to_json)

          end
        end
      end
    end


    def process_browser_device_record_video_request(user_id)

      if @session.authenticated? user_id then
        device_id = @json['command_parameters']['device_id'].to_i
        device_client_info = @session.get_device_info(device_id)

        if !device_client_info.nil? then
          device_client = @clients.select{|client| client.object_id == device_client_info.id}.first

          if !device_client.nil? then
            device_client.send({
              :command => {
                :name => DEVICE_RECORD_VIDEO_REQUEST
              },
              :command_parameters => {
                :request_user_id => user_id
              }
            }.to_json)

          end
        end
      end
    end

    #---------------------------------------------------------------------------------------------| DEVICE CLIENT |-----------------------

    def process_device_incoming_message(device_id)
      command_name = @json['command']['name']
      p command_name
      case command_name
        when CONNECT_REQUEST then
          process_device_connect_request(device_id)
        when DEVICE_GET_CONTACTS_RESPONSE then
          process_device_device_get_contacts_response(device_id)
        when DEVICE_GET_CALL_HISTORY_RESPONSE then
          process_device_device_get_call_history_response(device_id)
        when DEVICE_GET_LOCATION_RESPONSE then
          process_device_device_get_location_response(device_id)
        when DEVICE_TAKE_PHOTO_RESPONSE then
          process_device_device_take_photo_response(device_id)
        when DEVICE_RECORD_VIDEO_RESPONSE then
          process_device_device_record_video_response(device_id)
      end
    end


    def process_device_connect_request(device_id)
      @session.set(@current_client.object_id, "ios", device_id)
      success_result(CONNECT_RESPONSE)
    end


    def process_device_info_request(device_id)
      @client_info = @session.client_infos[@current_client.object_id]
      device = Device.find(@client_info.device_id)
      @current_client.send({
        :status => "1",
        :command => {
          :name => CLIENTINFO_RESPONSE
        },
        :client_info => {
          :name => device.name
        }
      }.to_json)
    end


    def process_device_device_get_contacts_response(device_id)

      if @session.authenticated? device_id then
        user_id = @json['command_parameters']['request_user_id'].to_i
        user_client_info = @session.get_user_info(user_id)

        if !user_client_info.nil? then
          user_client = @clients.select{|client| client.object_id == user_client_info.id }.first

          if !user_client.nil? then
            user_client.send({
              :command => {
                :name => DEVICE_GET_CONTACTS_RESPONSE
              },
              :command_parameters => {
                :contacts => @json['command_parameters']['contacts']
              }
            }.to_json)

          end
        end
      end
    end


    def process_device_device_get_call_history_response(device_id)

      if @session.authenticated? device_id then
        user_id = @json['command_parameters']['request_user_id'].to_i
        user_client_info = @session.get_user_info(user_id)

        if !user_client_info.nil? then
          user_client = @clients.select{|client| client.object_id == user_client_info.id }.first

          if !user_client.nil? then
            user_client.send({
              :command => {
                :name => DEVICE_GET_CALL_HISTORY_RESPONSE
              },
              :command_parameters => {
                :call_history_items => @json['command_parameters']['call_history_items']
              }
            }.to_json)

          end
        end
      end
    end


    def process_device_device_get_location_response(device_id)
      
      if @session.authenticated? device_id then
        user_id = @json['command_parameters']['request_user_id'].to_i
        user_client_info = @session.get_user_info(user_id)

        if !user_client_info.nil? then
          user_client = @clients.select{|client| client.object_id == user_client_info.id }.first

          if !user_client.nil? then
            user_client.send({
              :command => {
                :name => DEVICE_GET_LOCATION_RESPONSE
              },
              :command_parameters => {
                :location_latitude => @json['command_parameters']['location_latitude'],
                :location_longitude => @json['command_parameters']['location_longitude']
              }
            }.to_json)

          end
        end
      end
    end


    def process_device_device_take_photo_response(device_id)

      if @session.authenticated? device_id then
        user_id = @json['command_parameters']['request_user_id'].to_i
        user_client_info = @session.get_user_info(user_id)

        if !user_client_info.nil? then
          user_client = @clients.select{|client| client.object_id == user_client_info.id }.first

          if !user_client.nil? then
            user_client.send({
              :command => {
                :name => DEVICE_TAKE_PHOTO_RESPONSE
              },
              :command_parameters => {
                :base64_string_photo => @json['command_parameters']['base64_string_photo']
              }
            }.to_json)

          end
        end
      end
    end


    def process_device_device_record_video_response(device_id)

      if @session.authenticated? device_id then
        user_id = @json['command_parameters']['request_user_id'].to_i
        user_client_info = @session.get_user_info(user_id)

        if !user_client_info.nil? then
          user_client = @clients.select{|client| client.object_id == user_client_info.id }.first

          if !user_client.nil? then
            user_client.send({
              :command => {
                :name => DEVICE_RECORD_VIDEO_RESPONSE
              },
              :command_parameters => {
                :base64_string_video => @json['command_parameters']['base64_string_video']
              }
            }.to_json)

          end
        end
      end
    end

    #---------------------------------------------------------------------------------------------------| AUXILIARIES |------------------
    def forbidden_result(command_name)
      @current_client.send({
        :status => "-1",
        :command => {
          :name => command_name
        }
      }.to_json)
    end

    def success_result(command_name)
      @current_client.send({
        :status => "1",
        :command => {
          :name => command_name
        }
      }.to_json)
    end
  end

  class WebSocketClient
    attr_accessor :id, :type, :user_id, :device_id
  end 
end