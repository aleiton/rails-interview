# frozen_string_literal: true

module Sync
  class PushExecutor
    LOG_TAG = "[Sync::PushExecutor]"

    attr_reader :errors

    def initialize(api_client:, push_creates:, push_updates:, push_deletes:)
      @api = api_client
      @push_creates = push_creates
      @push_updates = push_updates
      @push_deletes = push_deletes
      @errors = []
    end

    def execute
      @push_creates.each { |local| create_list(local) }
      @push_updates.each { |pair| update_list(pair[:external], pair[:local]) }
      @push_deletes.each { |ext| delete_list(ext) }
      self
    end

    private

    def create_list(local)
      items = local[:items].map do |item|
        { source_id: item[:id], description: item[:description], completed: item[:completed] }
      end

      result = @api.create_list(source_id: local[:id], name: local[:name], items: items)
      now = Time.current

      list = TodoList.find(local[:id])
      list.update!(external_id: result["id"], synced_at: now)

      (result["items"] || []).each do |ext_item|
        next if ext_item["source_id"].blank?

        item = list.todo_items.find_by(id: ext_item["source_id"])
        item&.update!(external_id: ext_item["id"], synced_at: now)
      end
    rescue StandardError => e
      record_error(:push_create, local[:id], e)
    end

    def update_list(ext, local)
      @api.update_list(external_id: ext[:external_id], name: local[:name])

      sync_item_updates(ext, local)

      now = Time.current
      list = TodoList.find(local[:id])
      list.update!(synced_at: now)
      list.todo_items.synced.update_all(synced_at: now)
    rescue StandardError => e
      record_error(:push_update, ext[:external_id], e)
    end

    def delete_list(ext)
      @api.delete_list(external_id: ext[:external_id])
    rescue StandardError => e
      return if e.is_a?(ExternalApiClient::ApiError) && e.status == 404

      record_error(:push_delete, ext[:external_id], e)
    end

    def sync_item_updates(ext, local)
      ext_items_by_id = ext[:items].index_by { |i| i[:external_id] }

      local[:items].select { |i| i[:external_id].present? }.each do |local_item|
        ext_item = ext_items_by_id[local_item[:external_id]]

        if ext_item
          @api.update_item(
            list_external_id: ext[:external_id],
            item_external_id: local_item[:external_id],
            description: local_item[:description],
            completed: local_item[:completed]
          )
        else
          delete_item(ext[:external_id], local_item[:external_id])
        end
      end
    end

    def delete_item(list_ext_id, item_ext_id)
      @api.delete_item(list_external_id: list_ext_id, item_external_id: item_ext_id)
    rescue StandardError => e
      return if e.is_a?(ExternalApiClient::ApiError) && e.status == 404

      record_error(:push_delete_item, item_ext_id, e)
    end

    def record_error(action, identifier, error)
      Rails.logger.error("#{LOG_TAG} #{action} failed for #{identifier}: #{error.message}")
      @errors << { action: action, identifier: identifier, error: error.message }
    end
  end
end
