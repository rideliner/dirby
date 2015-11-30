
require 'dirby/proxy'

module Dirby
  class DistributedObject
    def self._load(s)
      SemiObjectProxy.new(*Marshal.load(s))
    end

    def _dump(_)
      Marshal.dump [@server.uri, @server.to_id(@obj)]
    end

    def initialize(obj, server)
      @obj = obj
      @server = server
    end

    undef :to_s
    undef :to_a if respond_to?(:to_a)

    def respond_to?(msg_id, priv = false)
      responds =
        case msg_id
        when :_dump
          true
        when :marshal_dump
          false
        else
          method_missing(:respond_to?, msg_id, priv)
        end

      @server.log.debug("respond_to?(#{msg_id}) => #{responds}")
      responds
    end

    def method_missing(msg_id, *args, &block)
      # TODO: check insecure method
      @server.log.debug("calling: #{msg_id} #{args.join ', '}")
      @obj.__send__(msg_id, *args, &block)
    end
  end
end
