# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sync::SnapshotBuilder do
  describe ".build_external" do
    it "indexes lists by external id with normalized items" do
      api_data = [
        {
          "id" => "ext-1",
          "source_id" => "10",
          "name" => "Groceries",
          "updated_at" => "2026-02-15T12:00:00Z",
          "items" => [
            { "id" => "item-1", "source_id" => "20", "description" => "Buy milk",
              "completed" => false, "updated_at" => "2026-02-15T12:00:00Z" }
          ]
        }
      ]

      result = described_class.build_external(api_data)

      expect(result.keys).to eq(["ext-1"])
      expect(result["ext-1"][:name]).to eq("Groceries")
      expect(result["ext-1"][:source_id]).to eq("10")
      expect(result["ext-1"][:items].length).to eq(1)
      expect(result["ext-1"][:items].first[:external_id]).to eq("item-1")
    end
  end

  describe ".build_local" do
    it "splits lists into synced and unsynced" do
      synced_list = TodoList.create!(name: "Synced", external_id: "ext-1")
      TodoList.create!(name: "Unsynced")
      synced_list.todo_items.create!(description: "Synced item", external_id: "item-1")

      result = described_class.build_local

      expect(result[:synced].keys).to eq(["ext-1"])
      expect(result[:synced]["ext-1"][:name]).to eq("Synced")
      expect(result[:synced]["ext-1"][:items].length).to eq(1)
      expect(result[:unsynced].length).to eq(1)
      expect(result[:unsynced].first[:name]).to eq("Unsynced")
    end
  end
end
