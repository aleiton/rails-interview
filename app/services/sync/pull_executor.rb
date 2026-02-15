# frozen_string_literal: true

module Sync
  class PullExecutor
    LOG_TAG = "[Sync::PullExecutor]"

    attr_reader :errors

    def initialize(pull_creates:, pull_updates:, pull_deletes:)
      @pull_creates = pull_creates
      @pull_updates = pull_updates
      @pull_deletes = pull_deletes
      @errors = []
    end

    def execute
      @pull_creates.each { |ext| create_list(ext) }
      @pull_updates.each { |pair| update_list(pair[:external], pair[:local]) }
      @pull_deletes.each { |local| delete_list(local) }
      self
    end

    private

    def create_list(ext)
      list = nil

      ActiveRecord::Base.transaction do
        list = TodoList.create!(
          name: ext[:name],
          external_id: ext[:external_id]
        )

        ext[:items].each do |ext_item|
          list.todo_items.create!(
            description: ext_item[:description],
            completed: ext_item[:completed] || false,
            external_id: ext_item[:external_id]
          )
        end
      end

      now = Time.current
      list.update_column(:synced_at, now)
      list.todo_items.update_all(synced_at: now)
    rescue StandardError => e
      Rails.logger.error("#{LOG_TAG} pull_create failed for #{ext[:external_id]}: #{e.message}")
      @errors << { action: :pull_create, external_id: ext[:external_id], error: e.message }
    end

    def update_list(ext, local)
      now = Time.current

      ActiveRecord::Base.transaction do
        list = TodoList.find(local[:id])
        list.update!(name: ext[:name])
        list.update_column(:synced_at, now)

        sync_items(list, ext[:items], local[:items], now)
      end
    rescue StandardError => e
      Rails.logger.error("#{LOG_TAG} pull_update failed for #{ext[:external_id]}: #{e.message}")
      @errors << { action: :pull_update, external_id: ext[:external_id], error: e.message }
    end

    def delete_list(local)
      TodoList.find(local[:id]).destroy!
    rescue StandardError => e
      Rails.logger.error("#{LOG_TAG} pull_delete failed for local id #{local[:id]}: #{e.message}")
      @errors << { action: :pull_delete, local_id: local[:id], error: e.message }
    end

    def sync_items(list, ext_items, local_items, now)
      local_by_ext_id = local_items.select { |i| i[:external_id].present? }
                                   .index_by { |i| i[:external_id] }
      ext_by_id = ext_items.index_by { |i| i[:external_id] }

      ext_items.each do |ext_item|
        local_item = local_by_ext_id[ext_item[:external_id]]

        if local_item
          item = TodoItem.find(local_item[:id])
          item.update!(description: ext_item[:description], completed: ext_item[:completed] || false)
          item.update_column(:synced_at, now)
        else
          new_item = list.todo_items.create!(
            description: ext_item[:description],
            completed: ext_item[:completed] || false,
            external_id: ext_item[:external_id]
          )
          new_item.update_column(:synced_at, now)
        end
      end

      local_by_ext_id.each do |ext_id, local_item|
        next if ext_by_id.key?(ext_id)

        TodoItem.find(local_item[:id]).destroy!
      end
    end
  end
end
