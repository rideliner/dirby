
require 'dirby/tunnel/abstract'

module Dirby
  class BasicTunnel < AbstractTunnel
    def initialize(server, strategy, user, host)
      @working = true

      super(server, strategy, user, host)
    end

    def wait(ssh)
      ssh.loop { @working }
    end

    def close # TODO: test this
      @working = false
      super
    end
  end

  class BasicSpawnTunnel < AbstractTunnel
    def initialize(server, strategy, command, user, host)
      @command = command

      super(server, strategy, user, host)
    end

    def get_and_write_ports(ssh, output)
      @command.set_dynamic_mode unless @tunnel.server_port

      @channel = ssh.open_channel do |ch|
        ch.exec @command.to_cmd do |_, success|
          raise SpawnError, 'could not spawn host' unless success

          # it is already triggered if the port is set
          get_remote_server_port(ch) if @command.dynamic?
        end
      end

      ssh.loop { !@channel[:triggered] } if @command.dynamic?
      @channel.eof!

      super
    end

    def get_remote_server_port(ch)
      ch[:data] = ''
      ch[:triggered] = false

      ch.on_data do |_, data|
        ch[:data] << data
      end

      ch.on_extended_data do |_, _, data|
        @server.log(data.inspect)
      end

      ch.on_process do |_|
        if !ch[:triggered] && ch[:data] =~ /Running on port (\d+)\./
          @strategy.instance_variable_set(:@server_port, $~[1])
          ch[:triggered] = true
        end
      end
    end

    def wait(ssh)
      ssh.loop { @channel.active? }
    end
  end
end
