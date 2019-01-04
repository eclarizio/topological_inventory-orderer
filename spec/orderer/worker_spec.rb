require "topological_inventory/orderer/worker"

describe TopologicalInventory::Orderer::Worker do
  let(:client) { double(:client) }

  describe "#run" do
    let(:messages) { [ManageIQ::Messaging::ReceivedMessage.new(nil, nil, payload, nil)] }
    let(:task) { Task.create!(:tenant => tenant) }
    let(:tenant) { Tenant.create! }
    let(:service_plan) do
      ServicePlan.create!(:source           => source,
                          :tenant           => tenant,
                          :name             => "plan_name",
                          :service_offering => service_offering)
    end
    let(:source) { Source.create!(:tenant => tenant, :uid => SecureRandom.uuid) }
    let(:service_offering) do
      ServiceOffering.create!(:source => source, :tenant => tenant, :name => "service_offering")
    end
    let(:payload) { {:service_plan_id => service_plan.id, :order_params => "order_params", :task_id => task.id} }

    before do
      allow(ManageIQ::Messaging::Client).to receive(:open).and_return(client)
      allow(client).to receive(:close)
      allow(client).to receive(:subscribe_messages).and_yield(messages)

      # This looks silly but without it when it finds the service plan, the 'allow'
      # is no longer on the same object and so there is no way to create an expectation
      allow(ServicePlan).to receive(:find).with(service_plan.id).and_return(service_plan)
      allow(service_plan).to receive(:order)
    end

    it "orders the service" do
      expect(service_plan).to receive(:order).with("order_params")
      described_class.new.run
    end

    it "updates the task with the status 'completed'" do
      described_class.new.run
      task.reload
      expect(task.status).to eq("completed")
    end
  end
end
