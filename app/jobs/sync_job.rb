# frozen_string_literal: true

class SyncJob < ApplicationJob
  queue_as :default

  LOG_TAG = '[SyncJob]'

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  discard_on(StandardError) do |_job, error|
    Rails.logger.error("#{LOG_TAG} Discarded: #{error.message}")
  end

  def perform
    result = Sync::Orchestrator.new.run

    if result.nil?
      Rails.logger.info("#{LOG_TAG} Skipped: sync already in progress")
    else
      Rails.logger.info("#{LOG_TAG} Finished: #{result.to_h.except(:errors)}")
    end
  end
end
