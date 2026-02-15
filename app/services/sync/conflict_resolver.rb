# frozen_string_literal: true

module Sync
  class ConflictResolver
    def self.resolve(ext_updated_at:, local_updated_at:, synced_at:)
      ext_changed = synced_at.nil? || (ext_updated_at && ext_updated_at > synced_at)
      local_changed = synced_at.nil? || local_updated_at > synced_at

      return :pull if ext_changed && !local_changed
      return :push if local_changed && !ext_changed
      return :none unless ext_changed || local_changed

      if ext_updated_at && local_updated_at
        ext_updated_at >= local_updated_at ? :pull : :push
      elsif ext_updated_at
        :pull
      else
        :push
      end
    end
  end
end
