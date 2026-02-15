# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sync::DiffCalculator do
  let(:now) { Time.zone.parse("2026-02-15 12:00:00") }
  let(:synced_at) { now - 1.day }

  def make_external(id:, source_id: nil, updated_at: now, items: [])
    { external_id: id, source_id: source_id, name: "List #{id}", updated_at: updated_at, items: items }
  end

  def make_local(id:, external_id: nil, updated_at: now, synced_at: nil, items: [])
    { id: id, external_id: external_id, name: "List #{id}", updated_at: updated_at, synced_at: synced_at, items: items }
  end

  it "detects pull_creates for new external lists" do
    external = { "ext-1" => make_external(id: "ext-1") }
    local = { synced: {}, unsynced: [] }

    diff = described_class.new(external_snapshot: external, local_snapshot: local)

    expect(diff.pull_creates.length).to eq(1)
    expect(diff.pull_creates.first[:external_id]).to eq("ext-1")
  end

  it "detects pull_deletes for synced local lists missing externally" do
    external = {}
    local = { synced: { "ext-1" => make_local(id: 1, external_id: "ext-1") }, unsynced: [] }

    diff = described_class.new(external_snapshot: external, local_snapshot: local)

    expect(diff.pull_deletes.length).to eq(1)
    expect(diff.pull_deletes.first[:id]).to eq(1)
  end

  it "detects pull_updates when external wins conflict" do
    external = { "ext-1" => make_external(id: "ext-1", updated_at: now) }
    local = { synced: { "ext-1" => make_local(id: 1, external_id: "ext-1", updated_at: now - 2.hours, synced_at: synced_at) }, unsynced: [] }

    diff = described_class.new(external_snapshot: external, local_snapshot: local)

    expect(diff.pull_updates.length).to eq(1)
  end

  it "detects push_updates when local wins conflict" do
    external = { "ext-1" => make_external(id: "ext-1", updated_at: now - 2.hours) }
    local = { synced: { "ext-1" => make_local(id: 1, external_id: "ext-1", updated_at: now, synced_at: synced_at) }, unsynced: [] }

    diff = described_class.new(external_snapshot: external, local_snapshot: local)

    expect(diff.push_updates.length).to eq(1)
  end

  it "detects push_creates for unsynced local lists" do
    external = {}
    local = { synced: {}, unsynced: [make_local(id: 1)] }

    diff = described_class.new(external_snapshot: external, local_snapshot: local)

    expect(diff.push_creates.length).to eq(1)
  end

  it "detects push_deletes for external lists whose source_id has no local match" do
    TodoList.create!(name: "Existing", external_id: "ext-2")
    external = { "ext-1" => make_external(id: "ext-1", source_id: "999") }
    local = { synced: {}, unsynced: [] }

    diff = described_class.new(external_snapshot: external, local_snapshot: local)

    expect(diff.push_deletes.length).to eq(1)
    expect(diff.push_deletes.first[:external_id]).to eq("ext-1")
  end
end
