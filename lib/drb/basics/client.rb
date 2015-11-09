
require 'drb/basics/messenger'

module DRb
  class BasicClient < Messenger
    def initialize(server, stream, remote_uri)
      super(server, stream)

      @remote_uri = remote_uri

      # write the other side's remote_uri to the socket
      @stream.write(dump_data(@remote_uri))
    end

    def send_request(ref, msg_id, arg, b)
      arr = [ ]
      arr << dump_data(ref)
      arr << dump_data(msg_id.id2name)
      arr << dump_data(arg.length)
      arg.each { |e| arr << dump_data(e) }
      arr << dump_data(b)
      @stream.write(arr.join(''))
    end

    def recv_reply
      succ = load_data(@server.load_limit)
      result = load_data(@server.load_limit)
      [ succ, result ]
    end
  end
end
