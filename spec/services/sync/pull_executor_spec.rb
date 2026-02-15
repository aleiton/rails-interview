# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sync::PullExecutor do
  it "creates a local list with items from external data" do
    ext = {
      external_id: "ext-1", name: "Groceries", updated_at: Time.current,
      items: [
        { external_id: "item-1", description: "Buy milk", completed: false, updated_at: Time.current }
      ]
    }

    executor = described_class.new(pull_creates: [ext], pull_updates: [], pull_deletes: [])
    executor.execute

    list = TodoList.find_by(external_id: "ext-1")
    expect(list).to be_present
    expect(list.name).to eq("Groceries")
    expect(list.todo_items.count).to eq(1)
    expect(list.todo_items.first.external_id).to eq("item-1")
  end

  it "updates a local list and syncs its items" do
    list = TodoList.create!(name: "Old Name", external_id: "ext-1")
    item = list.todo_items.create!(description: "Old description", external_id: "item-1")

    ext = {
      external_id: "ext-1", name: "New Name", updated_at: Time.current,
      items: [
        { external_id: "item-1", description: "New description", completed: true, updated_at: Time.current }
      ]
    }
    local = { id: list.id, items: [{ id: item.id, external_id: "item-1" }] }

    executor = described_class.new(pull_creates: [], pull_updates: [{ external: ext, local: local }], pull_deletes: [])
    executor.execute

    list.reload
    expect(list.name).to eq("New Name")
    expect(list.todo_items.first.description).to eq("New description")
    expect(list.todo_items.first.completed).to be(true)
  end

  it "deletes a local list that was removed externally" do
    list = TodoList.create!(name: "To Delete", external_id: "ext-1")
    list.todo_items.create!(description: "Some item")
    local = { id: list.id, external_id: "ext-1" }

    executor = described_class.new(pull_creates: [], pull_updates: [], pull_deletes: [local])
    executor.execute

    expect(TodoList.find_by(id: list.id)).to be_nil
  end
end
