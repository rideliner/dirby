
require 'dirby/protocol/basic'
require 'dirby/server/abstract'

module Dirby
  class DeadProtocol
    include BasicProtocol

    self.scheme = ''

    refine(:server, '') do |_, config|
      fail NonAcceptingServer, Server.new(config)
    end

    class Server < AbstractServer
      # A DeadProtocol server doesn't allow backwards connections
      # therefore, making a distributed object goes against that.
      def make_distributed(*_)
        fail DistributedError,
             'distributed objects not supported from DeadProtocol'
      end
    end
  end
end
