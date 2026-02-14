class AddTimestampsToTodoLists < ActiveRecord::Migration[7.0]
  def change
    add_timestamps :todo_lists, default: Time.zone.now
    change_column_default :todo_lists, :created_at, from: Time.zone.now, to: nil
    change_column_default :todo_lists, :updated_at, from: Time.zone.now, to: nil
  end
end
