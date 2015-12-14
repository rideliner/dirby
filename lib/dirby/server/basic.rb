
require 'dirby/stream/query_ref'
require 'dirby/utility/polymorphic_delegated'
require 'dirby/utility/self_pipe'
require 'dirby/utility/monitor'

require 'io/wait'

module Dirby
  class BasicServer < AbstractServer
    extend ClassicAttributeAccess

    def initialize(uri, front, stream, config)
      super(config) { |msg| "#{uri} : #{msg}" }

      @uri = uri
      @front = front
      @stream = stream

      @exported_uri = Dirby.monitor([@uri])

      @shutdown_pipe = SelfPipe.new(*IO.pipe)
    end

    def close
      log.debug('Closing')
      if stream
        stream.close
        self.stream = nil
      end

      close_shutdown_pipe
    end

    def shutdown
      log.debug('Shutting down')
      shutdown_pipe.close_write if shutdown_pipe
    end

    def accept
      readables, = IO.select([stream, shutdown_pipe.read])
      fail LocalServerShutdown if readables.include? shutdown_pipe.read
      log.debug('Accepting connection')
      stream.accept
    end

    def alive?
      return false unless stream
      return true if stream.ready?

      shutdown
      false
    end

    def to_obj(ref)
      case ref
      when nil
        front
      when QueryRef
        front[ref.to_s]
      else
        idconv.to_obj(ref)
      end
    end

    def to_id(obj)
      return nil if obj.__id__ == front.__id__
      idconv.to_id(obj)
    end

    attr_reader :uri
    config_reader :argc_limit

    def add_uri_alias(uri)
      log.debug("Adding uri alias: #{uri}")

      exported_uri.synchronize do
        exported_uri << uri unless exported_uri.include?(uri)
      end
    end

    def here?(uri)
      exported_uri.synchronize { exported_uri.include?(uri) }
    end

    private

    config_reader :idconv
    attr_reader :front, :exported_uri
    attr_accessor :stream, :shutdown_pipe

    def close_shutdown_pipe
      return nil unless shutdown_pipe

      log.debug('Closing shutdown pipe')
      shutdown_pipe.close_read
      shutdown_pipe.close_write
      self.shutdown_pipe = nil
    end
  end
end
