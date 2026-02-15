# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sync::PushExecutor do
  let(:base_url) { "http://external-api.test" }
  let(:api_client) { Sync::ExternalApiClient.new(base_url: base_url) }

  it "creates a list externally and stores the returned external_id" do
    list = TodoList.create!(name: "New List")
    item = list.todo_items.create!(description: "New item")

    local = {
      id: list.id, name: list.name,
      items: [{ id: item.id, description: item.description, completed: false }]
    }

    stub_request(:post, "#{base_url}/todolists")
      .to_return(
        status: 201,
        body: { "id" => "ext-1", "items" => [{ "id" => "item-ext-1", "source_id" => item.id.to_s }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    executor = described_class.new(api_client: api_client, push_creates: [local], push_updates: [], push_deletes: [])
    executor.execute

    list.reload
    expect(list.external_id).to eq("ext-1")
    expect(list.synced_at).to be_present
    expect(item.reload.external_id).to eq("item-ext-1")
  end

  it "updates a list and its items externally" do
    list = TodoList.create!(name: "Updated", external_id: "ext-1")
    item = list.todo_items.create!(description: "Updated item", external_id: "item-1")

    ext = {
      external_id: "ext-1",
      items: [{ external_id: "item-1", description: "Old desc", completed: false }]
    }
    local = {
      id: list.id, name: "Updated",
      items: [{ id: item.id, external_id: "item-1", description: "Updated item", completed: true }]
    }

    stub_request(:patch, "#{base_url}/todolists/ext-1")
      .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:patch, "#{base_url}/todolists/ext-1/todoitems/item-1")
      .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })

    executor = described_class.new(api_client: api_client, push_creates: [], push_updates: [{ external: ext, local: local }], push_deletes: [])
    executor.execute

    expect(executor.errors).to be_empty
    expect(list.reload.synced_at).to be_present
  end

  it "treats 404 on delete as success" do
    stub_request(:delete, "#{base_url}/todolists/ext-gone")
      .to_return(status: 404, body: { "error" => "Not found" }.to_json, headers: { "Content-Type" => "application/json" })

    ext = { external_id: "ext-gone" }

    executor = described_class.new(api_client: api_client, push_creates: [], push_updates: [], push_deletes: [ext])
    executor.execute

    expect(executor.errors).to be_empty
  end
end
