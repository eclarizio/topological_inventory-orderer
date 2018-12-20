module TopologicalInventory
  module Orderer
    class << self
      attr_writer :logger
    end

    def self.logger
      @logger ||= Logger.new(STDOUT, :level => Logger::INFO)
    end

    module Logging
      def logger
        TopologicalInventory::Orderer.logger
      end
    end
  end
end
