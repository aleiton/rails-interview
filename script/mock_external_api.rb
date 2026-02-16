#!/usr/bin/env ruby
# frozen_string_literal: true

# Mock External API Server
# Implements the external Todo API spec for development/testing.
# Run: ruby script/mock_external_api.rb
# Serves on http://localhost:4000
#
# Designed to test ALL sync scenarios in a single bin/rake sync:run:
#
#   1. No action    — "Stable List" unchanged on both sides
#   2. Pull create  — "New External List" has no local match
#   3. Push create  — Local unsynced lists get pushed here
#   4. Pull update  — "Pull Test" renamed externally after last sync
#   5. Push update  — "Push Test" not changed here, changed locally
#   6. Conflict     — "Conflict Test" changed on both sides, external wins (newer)
#   7. Pull delete  — ext-deleted is gone, local still has external_id for it
#   8. Push delete  — "Orphan" has source_id pointing to non-existent local ID

require "bundler/setup"
require "webrick"
require "json"
require "securerandom"

PORT = ENV.fetch("PORT", 4000).to_i

# In-memory storage
$lists = {}
$items = {}

# Fixed UUIDs so Rails seeds can reference them
FIXED_IDS = {
  stable: "ext-stable-0001",
  pull_update: "ext-pull-update-0002",
  push_update: "ext-push-update-0003",
  conflict: "ext-conflict-0004",
  new_list: "ext-new-0005",
  orphan: "ext-orphan-0006"
}.freeze

# Fixed item UUIDs for synced lists (so seeds can set matching external_id)
FIXED_ITEM_IDS = {
  stable_1: "ext-item-stable-001",
  stable_2: "ext-item-stable-002",
  pull_1: "ext-item-pull-001",
  pull_2: "ext-item-pull-002",
  push_1: "ext-item-push-001",
  push_2: "ext-item-push-002",
  conflict_1: "ext-item-conflict-001",
  conflict_2: "ext-item-conflict-002"
}.freeze

def seed_data
  now = Time.now.utc
  old = (now - 14 * 86_400).iso8601  # 2 weeks ago (before synced_at in seeds)
  recent = now.iso8601                # now (after synced_at in seeds)

  lists = [
    # 1. Stable — not changed since sync (updated_at = old)
    { id: FIXED_IDS[:stable], name: "Stable List", updated_at: old, source_id: nil, items: [
      { id: FIXED_ITEM_IDS[:stable_1], description: "Stable item one", completed: false },
      { id: FIXED_ITEM_IDS[:stable_2], description: "Stable item two", completed: true }
    ]},

    # 4. Pull update — renamed externally AFTER last sync
    { id: FIXED_IDS[:pull_update], name: "Pull Test (renamed externally)", updated_at: recent, source_id: nil, items: [
      { id: FIXED_ITEM_IDS[:pull_1], description: "Pull item alpha", completed: false },
      { id: FIXED_ITEM_IDS[:pull_2], description: "Pull item beta", completed: true }
    ]},

    # 5. Push update — NOT changed externally (local will push)
    { id: FIXED_IDS[:push_update], name: "Push Test", updated_at: old, source_id: nil, items: [
      { id: FIXED_ITEM_IDS[:push_1], description: "Push item alpha", completed: false },
      { id: FIXED_ITEM_IDS[:push_2], description: "Push item beta", completed: false }
    ]},

    # 6. Conflict — changed externally (newer timestamp wins)
    { id: FIXED_IDS[:conflict], name: "Conflict - External Wins", updated_at: recent, source_id: nil, items: [
      { id: FIXED_ITEM_IDS[:conflict_1], description: "Conflict item updated externally", completed: true },
      { id: FIXED_ITEM_IDS[:conflict_2], description: "Conflict item added externally", completed: false }
    ]},

    # 2. Pull create — brand new, no local match
    { id: FIXED_IDS[:new_list], name: "New External List", updated_at: recent, source_id: nil, items: [
      { description: "Brand new external item", completed: false },
      { description: "Another new item", completed: true }
    ]},

    # 8. Push delete — source_id points to non-existent local ID
    { id: FIXED_IDS[:orphan], name: "Orphan Push (source deleted)", updated_at: old, source_id: "999999", items: [
      { description: "Orphan item", completed: false }
    ]}
  ]

  lists.each do |list_data|
    list_id = list_data[:id]
    ts = list_data[:updated_at]
    $lists[list_id] = {
      "id" => list_id, "source_id" => list_data[:source_id],
      "name" => list_data[:name],
      "created_at" => ts, "updated_at" => ts
    }
    list_data[:items].each do |item_data|
      item_id = item_data[:id] || SecureRandom.uuid
      $items[item_id] = {
        "id" => item_id, "source_id" => nil,
        "todo_list_id" => list_id,
        "description" => item_data[:description],
        "completed" => item_data[:completed],
        "created_at" => ts, "updated_at" => ts
      }
    end
  end
end

def items_for_list(list_id)
  $items.values.select { |i| i["todo_list_id"] == list_id }
end

def list_with_items(list)
  list.reject { |k, _| k == "todo_list_id" }
      .merge("items" => items_for_list(list["id"]).map { |i| i.reject { |k, _| k == "todo_list_id" } })
end

seed_data

# Single servlet that routes all /todolists* requests
class TodoServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    parts = path_parts(req)

    if parts == ["todolists"]
      res.content_type = "application/json"
      res.body = $lists.values.map { |l| list_with_items(l) }.to_json
    else
      not_found(res)
    end
  end

  def do_POST(req, res)
    parts = path_parts(req)

    if parts == ["todolists"]
      body = JSON.parse(req.body)
      list_id = SecureRandom.uuid
      now = Time.now.utc.iso8601
      list = {
        "id" => list_id, "source_id" => body["source_id"],
        "name" => body["name"],
        "created_at" => now, "updated_at" => now
      }
      $lists[list_id] = list

      (body["items"] || []).each do |item_body|
        item_id = SecureRandom.uuid
        $items[item_id] = {
          "id" => item_id, "source_id" => item_body["source_id"],
          "todo_list_id" => list_id,
          "description" => item_body["description"],
          "completed" => item_body["completed"] || false,
          "created_at" => now, "updated_at" => now
        }
      end

      res.status = 201
      res.content_type = "application/json"
      res.body = list_with_items(list).to_json
    else
      not_found(res)
    end
  end

  def do_PATCH(req, res)
    parts = path_parts(req)
    body = JSON.parse(req.body)

    if parts.length == 2 && parts[0] == "todolists"
      list = $lists[parts[1]]
      return not_found(res) unless list

      list["name"] = body["name"] if body["name"]
      list["updated_at"] = Time.now.utc.iso8601
      res.content_type = "application/json"
      res.body = list_with_items(list).to_json

    elsif parts.length == 4 && parts[2] == "todoitems"
      item = $items[parts[3]]
      return not_found(res) unless item && item["todo_list_id"] == parts[1]

      item["description"] = body["description"] if body.key?("description")
      item["completed"] = body["completed"] if body.key?("completed")
      item["updated_at"] = Time.now.utc.iso8601
      res.content_type = "application/json"
      res.body = item.reject { |k, _| k == "todo_list_id" }.to_json
    else
      not_found(res)
    end
  end

  def do_DELETE(req, res)
    parts = path_parts(req)

    if parts.length == 2 && parts[0] == "todolists"
      list = $lists[parts[1]]
      return not_found(res) unless list

      $lists.delete(parts[1])
      $items.reject! { |_, i| i["todo_list_id"] == parts[1] }
      res.status = 204

    elsif parts.length == 4 && parts[2] == "todoitems"
      item = $items[parts[3]]
      return not_found(res) unless item && item["todo_list_id"] == parts[1]

      $items.delete(parts[3])
      res.status = 204
    else
      not_found(res)
    end
  end

  private

  def path_parts(req)
    req.path.split("/").reject(&:empty?)
  end

  def not_found(res)
    res.status = 404
    res.content_type = "application/json"
    res.body = { error: "Not found" }.to_json
  end
end

server = WEBrick::HTTPServer.new(Port: PORT, Logger: WEBrick::Log.new($stdout, WEBrick::Log::INFO))
server.mount "/", TodoServlet

trap("INT") { server.shutdown }
trap("TERM") { server.shutdown }

puts ""
puts "=" * 60
puts "Mock External API running on http://localhost:#{PORT}"
puts "Pre-seeded with #{$lists.size} lists and #{$items.size} items"
puts "=" * 60
puts ""
puts "Expected sync results (single bin/rake sync:run):"
puts ""
puts "  1. No action   — 'Stable List' unchanged on both sides"
puts "  2. Pull create  — 'New External List' created locally"
puts "  3. Push create  — Local unsynced lists pushed here"
puts "  4. Pull update  — 'Pull Test' renamed locally from external"
puts "  5. Push update  — 'Push Test' renamed externally from local"
puts "  6. Conflict     — 'Conflict' external wins (newer timestamp)"
puts "  7. Pull delete  — Local 'Orphaned List' removed (external gone)"
puts "  8. Push delete  — 'Orphan Push' removed here (local source deleted)"
puts ""
puts "Second bin/rake sync:run should be idempotent (no changes)."
puts ""
puts "View state: curl -s http://localhost:#{PORT}/todolists | ruby -rjson -e '"
puts '  JSON.parse(STDIN.read).each { |l| puts "  #{l[\"name\"]} (id: #{l[\"id\"]}, source_id: #{l[\"source_id\"]}, items: #{l[\"items\"].size})" }'
puts "'"
puts ""
puts "Press Ctrl+C to stop"
puts ""

server.start
