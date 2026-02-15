# frozen_string_literal: true

namespace :sync do
  desc "Run bidirectional sync synchronously"
  task run: :environment do
    result = Sync::Orchestrator.new.run

    if result.nil?
      puts "Sync skipped: already in progress"
    else
      puts "Sync complete: #{result.to_h.except(:errors)}"
      puts "Errors: #{result.errors}" if result.errors.any?
    end
  end

  desc "Enqueue sync job for background processing"
  task enqueue: :environment do
    SyncJob.perform_later
    puts "SyncJob enqueued"
  end
end
