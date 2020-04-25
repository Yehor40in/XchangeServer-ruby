require 'json'
require 'digest'

module WSUtility
    class Session

        def initialize(path = File.expand_path("session/#{Time.new.strftime('%s')}sess.json"))
            @context_path = path
            @client_infos = Hash.new
            @auth = []
        end

        def add(key, value)
            @client_infos[key] = value
        end

        def set(key, type, id)
            case type
            when 'browser' then
                @client_infos[key].user_id = id
            when 'ios' then
                @client_infos[key].device_id = id
            end
            @client_infos[key].type = type
            p @client_infos
        end

        def remove(key)
            @client_infos.delete key
        end

        def authenticate(identifier)
            key = Digest::MD5.hexdigest(identifier)
            @auth << key if @auth.index(key).nil?
            return @auth.index key
        end

        def authenticated?(id)
            @auth[id].nil?
        end

        def get_device_info(id)
            @client_infos.select {|k, v| v.device_id == id }.map{|k, v| v }.first
        end

        def get_user_info(id)
            @client_infos.select {|k, v| v.user_id == id }.map{|k, v| v }.first
        end
        
    end
end