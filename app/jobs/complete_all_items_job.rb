class CompleteAllItemsJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 1_000
  PERCENTAGE_SCALE = 100.0
  LOG_TAG = "[CompleteAllItemsJob]"

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  discard_on(StandardError) do |job, error|
    todo_list_id = job.arguments.first
    Rails.logger.error("#{LOG_TAG} Error: #{error.message}")
    broadcast(todo_list_id, action: "error")
  end

  def perform(todo_list_id)
    todo_list = TodoList.find(todo_list_id)
    total = incomplete_items(todo_list).count

    if total == 0
      Rails.logger.info("#{LOG_TAG} Starting: list_id=#{todo_list_id}, total=0")
      Rails.logger.info("#{LOG_TAG} Completed: 0/0 in 0.0s")
      self.class.broadcast(todo_list_id, action: "completed", completed: 0, total: 0)
      return
    end

    process_batches(todo_list, todo_list_id, total)
  end

  private

  def process_batches(todo_list, todo_list_id, total)
    Rails.logger.info("#{LOG_TAG} Starting: list_id=#{todo_list_id}, total=#{total}")
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    incomplete_items(todo_list).in_batches(of: BATCH_SIZE) do |batch|
      batch_ids = batch.pluck(:id)
      batch.update_all(completed: true)
      completed_count = total - incomplete_items(todo_list).count
      percentage = (completed_count / total.to_f * PERCENTAGE_SCALE).round(1)

      Rails.logger.info("#{LOG_TAG} Progress: #{completed_count}/#{total} (#{percentage}%)")
      self.class.broadcast(todo_list_id, action: "progress", completed: completed_count, total: total,
                                         completed_ids: batch_ids)
    end

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(1)
    completed_count = total - incomplete_items(todo_list).count

    Rails.logger.info("#{LOG_TAG} Completed: #{completed_count}/#{total} in #{elapsed}s")
    self.class.broadcast(todo_list_id, action: "completed", completed: completed_count, total: total)
  end

  def incomplete_items(todo_list)
    todo_list.todo_items.where(completed: false)
  end

  def self.broadcast(todo_list_id, **payload)
    ActionCable.server.broadcast("todo_list_#{todo_list_id}", payload)
  end
end
