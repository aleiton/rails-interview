#!/usr/bin/env ruby
# frozen_string_literal: true

# Mock External API Server
# Implements the external Todo API spec for development/testing.
# Run: ruby script/mock_external_api.rb
# Serves on http://localhost:4000

require "bundler/setup"
require "webrick"
require "json"
require "securerandom"

PORT = ENV.fetch("PORT", 4000).to_i

# In-memory storage
$lists = {}
$items = {}

def seed_data
  [
    { name: "External Groceries", items: [
      { description: "Buy milk and eggs", completed: false },
      { description: "Fresh vegetables", completed: true },
      { description: "Bread and butter", completed: false }
    ]},
    { name: "External Work Tasks", items: [
      { description: "Review pull requests", completed: false },
      { description: "Update documentation", completed: false },
      { description: "Deploy staging environment", completed: true }
    ]},
    { name: "External Weekend Plans", items: [
      { description: "Clean the garage", completed: false },
      { description: "Visit the park", completed: false }
    ]}
  ].each do |list_data|
    list_id = SecureRandom.uuid
    now = Time.now.utc.iso8601
    $lists[list_id] = {
      "id" => list_id, "source_id" => nil,
      "name" => list_data[:name],
      "created_at" => now, "updated_at" => now
    }
    list_data[:items].each do |item_data|
      item_id = SecureRandom.uuid
      $items[item_id] = {
        "id" => item_id, "source_id" => nil,
        "todo_list_id" => list_id,
        "description" => item_data[:description],
        "completed" => item_data[:completed],
        "created_at" => now, "updated_at" => now
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

puts "Mock External API running on http://localhost:#{PORT}"
puts "Pre-seeded with #{$lists.size} lists and #{$items.size} items"
puts "Press Ctrl+C to stop"
server.start
