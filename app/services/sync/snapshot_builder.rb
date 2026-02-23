# frozen_string_literal: true

module Sync
  class SnapshotBuilder
    def self.build_external(api_data)
      api_data.each_with_object({}) do |list, hash|
        ext_id = list['id']
        hash[ext_id] = {
          external_id: ext_id,
          source_id: list['source_id'],
          name: list['name'],
          updated_at: parse_time(list['updated_at']),
          items: build_external_items(list['items'] || [])
        }
      end
    end

    def self.build_local
      synced = {}
      unsynced = []

      TodoList.includes(:todo_items).find_each do |list|
        entry = build_local_list(list)

        if list.external_id.present?
          synced[list.external_id] = entry
        else
          unsynced << entry
        end
      end

      { synced: synced, unsynced: unsynced }
    end

    def self.build_external_items(items)
      items.map do |item|
        {
          external_id: item['id'],
          source_id: item['source_id'],
          description: item['description'],
          completed: item['completed'],
          updated_at: parse_time(item['updated_at'])
        }
      end
    end
    private_class_method :build_external_items

    def self.build_local_list(list)
      {
        id: list.id,
        external_id: list.external_id,
        name: list.name,
        updated_at: list.updated_at,
        synced_at: list.synced_at,
        items: list.todo_items.map do |item|
          {
            id: item.id,
            external_id: item.external_id,
            description: item.description,
            completed: item.completed,
            updated_at: item.updated_at,
            synced_at: item.synced_at
          }
        end
      }
    end
    private_class_method :build_local_list

    def self.parse_time(str)
      return nil if str.blank?

      Time.zone.parse(str)
    end
    private_class_method :parse_time
  end
end
