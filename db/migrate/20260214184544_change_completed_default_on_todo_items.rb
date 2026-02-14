class ChangeCompletedDefaultOnTodoItems < ActiveRecord::Migration[7.0]
  def change
    change_column_default :todo_items, :completed, from: nil, to: false
    change_column_null :todo_items, :completed, false, false
  end
end
