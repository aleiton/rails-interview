class AddNotNullConstraintToTodoItemDescription < ActiveRecord::Migration[7.0]
  def change
    change_column_null :todo_items, :description, false
  end
end
