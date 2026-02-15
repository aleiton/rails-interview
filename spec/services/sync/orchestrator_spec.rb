# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sync::Orchestrator do
  let(:base_url) { "http://external-api.test" }
  let(:api_client) { Sync::ExternalApiClient.new(base_url: base_url) }
  let(:orchestrator) { described_class.new(api_client: api_client) }

  it "pulls new external lists and pushes local unsynced lists" do
    local_list = TodoList.create!(name: "Local Only")
    local_list.todo_items.create!(description: "Local item")

    stub_request(:get, "#{base_url}/todolists")
      .to_return(
        status: 200,
        body: [
          { "id" => "ext-1", "name" => "Remote Only", "updated_at" => Time.current.iso8601,
            "items" => [{ "id" => "item-1", "description" => "Remote item", "completed" => false,
                          "updated_at" => Time.current.iso8601 }] }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:post, "#{base_url}/todolists")
      .to_return(
        status: 201,
        body: { "id" => "ext-2", "items" => [{ "id" => "item-2", "source_id" => local_list.todo_items.first.id.to_s }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = orchestrator.run

    expect(result.pull_creates).to eq(1)
    expect(result.push_creates).to eq(1)
    expect(result.errors).to be_empty
    expect(TodoList.find_by(external_id: "ext-1")).to be_present
    expect(local_list.reload.external_id).to eq("ext-2")
  end

  it "returns nil when sync is already in progress" do
    release = Queue.new
    thread = Thread.new do
      Sync::Orchestrator::MUTEX.synchronize { release.pop }
    end
    sleep 0.05

    result = orchestrator.run

    expect(result).to be_nil
  ensure
    release&.push(true)
    thread&.join
  end
end
