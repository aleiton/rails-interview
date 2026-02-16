# frozen_string_literal: true

# Sync test seed — standalone, replaces db:seed for sync testing.
# Same as main seeds but without stress test, plus sync-linked lists.
#
# Usage: bin/rails runner db/seeds/sync.rb
# Then:  ruby script/mock_external_api.rb  (terminal 1)
#        bin/rake sync:run                  (terminal 2)

puts "Seeding database for sync testing..."

# Clear existing data
TodoItem.delete_all
TodoList.delete_all

synced_at = 1.week.ago
old_ts    = 2.weeks.ago

# ==========================================================================
# Regular lists (unsynced → scenario 3: push create)
# ==========================================================================

groceries = TodoList.create!(name: "Grocery Shopping")
groceries.todo_items.create!(description: "Buy milk and eggs", completed: true)
groceries.todo_items.create!(description: "Pick up fresh vegetables", completed: true)
groceries.todo_items.create!(description: "Get chicken breast", completed: false)
groceries.todo_items.create!(description: "Grab some bread", completed: false)
groceries.todo_items.create!(description: "Buy coffee beans", completed: false)

chores = TodoList.create!(name: "Weekend Chores")
chores.todo_items.create!(description: "Clean the kitchen", completed: true)
chores.todo_items.create!(description: "Do the laundry", completed: false)
chores.todo_items.create!(description: "Vacuum the living room", completed: false)
chores.todo_items.create!(description: "Take out the trash", completed: false)

work = TodoList.create!(name: "Work Tasks")
work.todo_items.create!(description: "Review pull requests", completed: true)
work.todo_items.create!(description: "Write API documentation", completed: true)
work.todo_items.create!(description: "Fix login page bug", completed: false)
work.todo_items.create!(description: "Deploy to staging environment", completed: false)
work.todo_items.create!(description: "Update project dependencies", completed: false)

# ==========================================================================
# Sync-linked lists (scenarios 1, 4, 5, 6, 7)
# ==========================================================================

# 1. Stable — unchanged on both sides → no action
stable = TodoList.create!(name: "Stable List")
stable.update_columns(external_id: "ext-stable-0001", synced_at: synced_at, updated_at: old_ts, created_at: old_ts)
i1 = stable.todo_items.create!(description: "Stable item one", completed: false)
i2 = stable.todo_items.create!(description: "Stable item two", completed: true)
i1.update_columns(external_id: "ext-item-stable-001", synced_at: synced_at, updated_at: old_ts)
i2.update_columns(external_id: "ext-item-stable-002", synced_at: synced_at, updated_at: old_ts)

# 4. Pull update — external renamed after sync, local unchanged → pull
pull = TodoList.create!(name: "Pull Test")
pull.update_columns(external_id: "ext-pull-update-0002", synced_at: synced_at, updated_at: old_ts, created_at: old_ts)
i1 = pull.todo_items.create!(description: "Pull item alpha", completed: false)
i2 = pull.todo_items.create!(description: "Pull item beta", completed: true)
i1.update_columns(external_id: "ext-item-pull-001", synced_at: synced_at, updated_at: old_ts)
i2.update_columns(external_id: "ext-item-pull-002", synced_at: synced_at, updated_at: old_ts)

# 5. Push update — local renamed after sync, external unchanged → push
push = TodoList.create!(name: "Push Test (locally renamed)")
push.update_columns(external_id: "ext-push-update-0003", synced_at: synced_at, created_at: old_ts)
# updated_at stays at Time.current — more recent than synced_at → local changed
i1 = push.todo_items.create!(description: "Push item alpha", completed: false)
i2 = push.todo_items.create!(description: "Push item beta", completed: false)
i1.update_columns(external_id: "ext-item-push-001", synced_at: synced_at, updated_at: old_ts)
i2.update_columns(external_id: "ext-item-push-002", synced_at: synced_at, updated_at: old_ts)

# 6. Conflict — both changed; external is newer → external wins (pull)
#    Items: matched (updated), local-only (preserved), external-only (added)
conflict = TodoList.create!(name: "Conflict - Local Edit")
conflict.update_columns(external_id: "ext-conflict-0004", synced_at: synced_at, updated_at: 3.days.ago, created_at: old_ts)
i1 = conflict.todo_items.create!(description: "Conflict item original", completed: false)
i1.update_columns(external_id: "ext-item-conflict-001", synced_at: synced_at, updated_at: 3.days.ago)
i2 = conflict.todo_items.create!(description: "Conflict item local only", completed: false)
i2.update_columns(synced_at: synced_at, updated_at: 3.days.ago)
# ext-item-conflict-002 has no local match → will be added during pull

# 7. Pull delete — external was deleted; local still references it → pull delete
orphaned = TodoList.create!(name: "Orphaned List (should be deleted)")
orphaned.update_columns(external_id: "ext-deleted", synced_at: synced_at, updated_at: old_ts, created_at: old_ts)
i1 = orphaned.todo_items.create!(description: "This list no longer exists externally", completed: false)
i1.update_columns(synced_at: synced_at, updated_at: old_ts)

# Scenarios 2 (pull create) and 8 (push delete) come from the mock API data.

puts "Seeded #{TodoList.count} lists with #{TodoItem.count} items."
