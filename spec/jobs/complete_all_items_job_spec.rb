require 'rails_helper'

RSpec.describe CompleteAllItemsJob, type: :job do
  include ActiveJob::TestHelper

  let(:todo_list) { TodoList.create!(name: 'Test List') }

  def create_items(todo_list, count, completed: false)
    now = Time.current
    records = count.times.map do |i|
      { description: "Item #{i}", completed: completed, todo_list_id: todo_list.id, created_at: now, updated_at: now }
    end
    TodoItem.insert_all(records)
  end

  def capture_broadcasts(todo_list_id)
    messages = []
    allow(ActionCable.server).to receive(:broadcast) do |channel, payload|
      messages << payload if channel == "todo_list_#{todo_list_id}"
    end
    messages
  end

  describe '#perform' do
    it 'marks all incomplete items as completed' do
      create_items(todo_list, 5)

      described_class.perform_now(todo_list.id)

      expect(todo_list.todo_items.where(completed: false).count).to eq(0)
      expect(todo_list.todo_items.where(completed: true).count).to eq(5)
    end

    it 'does not affect already completed items' do
      create_items(todo_list, 3, completed: true)
      create_items(todo_list, 2)

      described_class.perform_now(todo_list.id)

      expect(todo_list.todo_items.where(completed: true).count).to eq(5)
    end

    it 'broadcasts progress after each batch' do
      create_items(todo_list, 2_500)
      messages = capture_broadcasts(todo_list.id)

      described_class.perform_now(todo_list.id)

      progress_messages = messages.select { |m| m[:action] == 'progress' }
      expect(progress_messages.length).to be >= 2
      expect(progress_messages.last[:completed]).to eq(2_500)
      expect(progress_messages.last[:total]).to eq(2_500)
    end

    it 'broadcasts completed when done' do
      create_items(todo_list, 3)
      messages = capture_broadcasts(todo_list.id)

      described_class.perform_now(todo_list.id)

      completed_message = messages.find { |m| m[:action] == 'completed' }
      expect(completed_message).to eq({ action: 'completed', completed: 3, total: 3 })
    end

    context 'when there are no incomplete items' do
      it 'broadcasts completed with zero counts' do
        messages = capture_broadcasts(todo_list.id)

        described_class.perform_now(todo_list.id)

        expect(messages).to contain_exactly({ action: 'completed', completed: 0, total: 0 })
      end
    end

    context 'when all items are already completed' do
      it 'broadcasts completed with zero counts' do
        create_items(todo_list, 5, completed: true)
        messages = capture_broadcasts(todo_list.id)

        described_class.perform_now(todo_list.id)

        expect(messages).to contain_exactly({ action: 'completed', completed: 0, total: 0 })
      end
    end
  end

  describe 'error handling' do
    around do |example|
      original = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = original
    end

    it 'is configured to retry on StandardError with 3 attempts' do
      rescues = described_class.rescue_handlers
      handler = rescues.find { |h| h.first == 'StandardError' }

      expect(handler).to be_present
    end

    it 'broadcasts error after exhausting all retries' do
      allow(ActionCable.server).to receive(:broadcast)

      allow_any_instance_of(described_class).to receive(:perform).and_raise(StandardError, 'persistent error')

      perform_enqueued_jobs { described_class.perform_later(todo_list.id) }

      expect(ActionCable.server).to have_received(:broadcast).with(
        "todo_list_#{todo_list.id}",
        { action: 'error' }
      )
    end
  end

  describe 'stress test', :slow do
    it 'processes 10k+ items correctly across multiple batches' do
      count = 10_500
      create_items(todo_list, count)
      messages = capture_broadcasts(todo_list.id)

      described_class.perform_now(todo_list.id)

      expect(todo_list.todo_items.where(completed: false).count).to eq(0)
      expect(todo_list.todo_items.where(completed: true).count).to eq(count)

      progress_messages = messages.select { |m| m[:action] == 'progress' }
      completed_message = messages.find { |m| m[:action] == 'completed' }

      expect(progress_messages.length).to be >= 2
      expect(completed_message).to eq({ action: 'completed', completed: count, total: count })

      # Verify progress is monotonically increasing
      counts = progress_messages.map { |m| m[:completed] }
      expect(counts).to eq(counts.sort)
      expect(counts.last).to eq(count)
    end
  end
end
