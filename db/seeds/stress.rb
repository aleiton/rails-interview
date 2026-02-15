# frozen_string_literal: true

# Stress test seed: ~200K items across 100 lists
#
# Usage: bin/rails runner db/seeds/stress.rb

puts "Stress seeding database..."

TodoItem.destroy_all
TodoList.destroy_all

LIST_COUNT = 100
ITEMS_PER_LIST = 2_000
BATCH_SIZE = 1_000

lists = LIST_COUNT.times.map do |i|
  TodoList.create!(name: "Stress List #{i + 1}")
end

puts "Created #{lists.size} lists."

total = 0
lists.each_with_index do |list, i|
  records = ITEMS_PER_LIST.times.map do |j|
    {
      todo_list_id: list.id,
      description: "Item #{j + 1} of list #{i + 1} — stress test",
      completed: rand < 0.3,
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  records.each_slice(BATCH_SIZE) do |batch|
    TodoItem.insert_all(batch)
  end

  total += ITEMS_PER_LIST
  puts "  List #{i + 1}/#{LIST_COUNT}: #{ITEMS_PER_LIST} items (#{total} total)" if (i + 1) % 10 == 0
end

puts "Done! #{TodoList.count} lists, #{TodoItem.count} items."
