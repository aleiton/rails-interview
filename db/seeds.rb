# frozen_string_literal: true

puts 'Seeding database...'

# Clear existing data
TodoItem.destroy_all
TodoList.destroy_all

# Grocery shopping list
groceries = TodoList.create!(name: 'Grocery Shopping')
groceries.todo_items.create!(description: 'Buy milk and eggs', completed: true)
groceries.todo_items.create!(description: 'Pick up fresh vegetables', completed: true)
groceries.todo_items.create!(description: 'Get chicken breast', completed: false)
groceries.todo_items.create!(description: 'Grab some bread', completed: false)
groceries.todo_items.create!(description: 'Buy coffee beans', completed: false)

# Weekend chores
chores = TodoList.create!(name: 'Weekend Chores')
chores.todo_items.create!(description: 'Clean the kitchen', completed: true)
chores.todo_items.create!(description: 'Do the laundry', completed: false)
chores.todo_items.create!(description: 'Vacuum the living room', completed: false)
chores.todo_items.create!(description: 'Take out the trash', completed: false)

# Work tasks
work = TodoList.create!(name: 'Work Tasks')
work.todo_items.create!(description: 'Review pull requests', completed: true)
work.todo_items.create!(description: 'Write API documentation', completed: true)
work.todo_items.create!(description: 'Fix login page bug', completed: false)
work.todo_items.create!(description: 'Deploy to staging environment', completed: false)
work.todo_items.create!(description: 'Update project dependencies', completed: false)

puts "Seeded #{TodoList.count} lists with #{TodoItem.count} items."
