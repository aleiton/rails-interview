# frozen_string_literal: true

# Stress test seed: 200K items in a single list
#
# Usage: bin/rails runner db/seeds/stress.rb

puts "Stress seeding database..."

# Remove previous stress test list if it exists
TodoList.where(name: "Stress Test").destroy_all

ITEM_COUNT = 200_000
BATCH_SIZE = 5_000

list = TodoList.create!(name: "Stress Test")

puts "Created list: #{list.name}"

ITEM_COUNT.times.each_slice(BATCH_SIZE).with_index do |batch_range, i|
  records = batch_range.map do |j|
    {
      todo_list_id: list.id,
      description: "Stress item #{j + 1}",
      completed: rand < 0.3,
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  TodoItem.insert_all(records)
  puts "  #{(i + 1) * BATCH_SIZE} / #{ITEM_COUNT} items inserted"
end

puts "Done! #{TodoList.count} list, #{TodoItem.count} items."
