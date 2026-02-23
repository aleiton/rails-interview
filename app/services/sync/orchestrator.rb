# frozen_string_literal: true

module Sync
  class Orchestrator
    LOG_TAG = '[Sync::Orchestrator]'
    MUTEX = Mutex.new

    Result = Struct.new(:pull_creates, :pull_updates, :pull_deletes,
                        :push_creates, :push_updates, :push_deletes,
                        :errors, keyword_init: true)

    def initialize(api_client: nil)
      @api = api_client || ExternalApiClient.new
    end

    def run
      unless MUTEX.try_lock
        Rails.logger.warn("#{LOG_TAG} Sync already in progress, skipping")
        return nil
      end

      Rails.logger.info("#{LOG_TAG} Starting sync")
      log_sync_result(perform_sync)
    ensure
      MUTEX.unlock if MUTEX.owned?
    end

    private

    def log_sync_result(result)
      Rails.logger.info("#{LOG_TAG} Sync finished: #{result.to_h.except(:errors)}")
      Rails.logger.warn("#{LOG_TAG} Errors: #{result.errors}") if result.errors.any?
      result
    end

    def perform_sync
      diff = compute_diff
      pull = execute_pull(diff)
      push = execute_push(diff)
      build_result(diff, pull, push)
    end

    def compute_diff
      external_data = @api.fetch_all_lists
      external_snapshot = SnapshotBuilder.build_external(external_data)
      local_snapshot = SnapshotBuilder.build_local
      DiffCalculator.new(external_snapshot: external_snapshot, local_snapshot: local_snapshot)
    end

    def execute_pull(diff)
      PullExecutor.new(
        pull_creates: diff.pull_creates,
        pull_updates: diff.pull_updates,
        pull_deletes: diff.pull_deletes
      ).execute
    end

    def execute_push(diff)
      PushExecutor.new(
        api_client: @api,
        push_creates: diff.push_creates,
        push_updates: diff.push_updates,
        push_deletes: diff.push_deletes
      ).execute
    end

    def build_result(diff, pull, push)
      Result.new(
        pull_creates: diff.pull_creates.size,
        pull_updates: diff.pull_updates.size,
        pull_deletes: diff.pull_deletes.size,
        push_creates: diff.push_creates.size,
        push_updates: diff.push_updates.size,
        push_deletes: diff.push_deletes.size,
        errors: pull.errors + push.errors
      )
    end
  end
end
