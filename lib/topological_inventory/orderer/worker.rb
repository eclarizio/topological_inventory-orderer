require "manageiq-messaging"
require "topological_inventory/orderer/logging"
require "topological_inventory/orderer/workflow"
require "topological_inventory/schema"

module TopologicalInventory
  module Orderer
    class Worker
      include Logging

      def initialize(messaging_client_opts = {})
        self.messaging_client_opts = default_messaging_opts.merge(messaging_client_opts)
      end

      def run
        # Open a connection to the messaging service
        self.client = ManageIQ::Messaging::Client.open(messaging_client_opts)

        logger.info("Topological Inventory Orderer started...")

        client.subscribe_messages(queue_opts.merge(:max_bytes => 500000)) do |messages|
          messages.each { |msg| process_message(client, msg) }
        end
      ensure
        client&.close
      end

      def stop
        client&.close
        self.client = nil
      end

      private

      attr_accessor :messaging_client_opts, :client

      def process_message(client, msg)
        TopologicalInventory::Orderer::Workflow.new(load_persister(msg.payload), client, msg.payload).execute!
      rescue => e
        logger.error(e.message)
        logger.error(e.backtrace.join("\n"))
        nil
      end

      def schema_klass_name(name)
        "TopologicalInventory::Schema::#{name}"
      end

      def queue_opts
        {
          :service => "platform.topological-inventory.orderer",
        }
      end

      def default_messaging_opts
        {
          :protocol   => :Kafka,
          :client_ref => "orderer-worker",
          :group_ref  => "orderer-worker",
        }
      end
    end
  end
end
