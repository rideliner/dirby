
# require the whole package, minimizes command length
require 'dirby'
require 'dirby/utility/io_barrier'

module Dirby
  class << self
    def handle_static_spawned(uri, config, &block)
      handle_spawned(uri, config, block)
    end

    def handle_dynamic_spawned(uri, config, &block)
      handle_spawned(uri, config, block) do |service|
        $stdout.puts "Running on port #{service.server.port}"
      end
    end

    private

    def handle_spawned(uri, config, origin)
      service = nil

      barriers = [$stdout, $stdin, $stderr].map { |io| IOBarrier.new(io) }

      barriers.each(&:block)
      obj = origin.call
      barriers.each(&:allow)

      obj.define_singleton_method :__dirby_exit__ do
        service.close unless service.nil?
      end

      service = Service.new(uri, obj, Marshal.load(config))
      yield service if block_given?
      service.wait
    end
  end
end
