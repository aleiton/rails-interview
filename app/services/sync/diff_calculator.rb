# frozen_string_literal: true

module Sync
  class DiffCalculator
    attr_reader :pull_creates, :pull_updates, :pull_deletes,
                :push_creates, :push_updates, :push_deletes

    def initialize(external_snapshot:, local_snapshot:)
      @external = external_snapshot
      @local_synced = local_snapshot[:synced]
      @local_unsynced = local_snapshot[:unsynced]

      @pull_creates = []
      @pull_updates = []
      @pull_deletes = []
      @push_creates = []
      @push_updates = []
      @push_deletes = []

      compute
    end

    private

    def compute
      detect_push_deletes
      detect_pulls
      detect_push_creates
    end

    def detect_pulls
      local_ext_ids = Set.new(@local_synced.keys)
      push_delete_ids = Set.new(@push_deletes.map { |e| e[:external_id] })

      classify_external_lists(local_ext_ids, push_delete_ids)
      collect_pull_deletes
    end

    def classify_external_lists(local_ext_ids, push_delete_ids)
      @external.each do |ext_id, ext_list|
        next if push_delete_ids.include?(ext_id)

        if local_ext_ids.include?(ext_id)
          resolve_conflict(ext_list, @local_synced[ext_id])
        else
          @pull_creates << ext_list
        end
      end
    end

    def collect_pull_deletes
      @local_synced.each do |ext_id, local_list|
        @pull_deletes << local_list unless @external.key?(ext_id)
      end
    end

    def resolve_conflict(ext_list, local_list)
      action = ConflictResolver.resolve(
        ext_updated_at: ext_list[:updated_at],
        local_updated_at: local_list[:updated_at],
        synced_at: local_list[:synced_at]
      )

      case action
      when :pull
        @pull_updates << { external: ext_list, local: local_list }
      when :push
        @push_updates << { external: ext_list, local: local_list }
      end
    end

    def detect_push_creates
      @push_creates = @local_unsynced.dup
    end

    def detect_push_deletes
      local_ids = Set.new(TodoList.pluck(:id).map(&:to_s))

      @external.each_value do |ext_list|
        next if ext_list[:source_id].blank?

        @push_deletes << ext_list unless local_ids.include?(ext_list[:source_id])
      end
    end
  end
end
