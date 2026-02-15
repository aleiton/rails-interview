json.items @todo_items, :id, :description, :completed, :todo_list_id, :created_at, :updated_at

json.meta do
  json.total_count @total_count
  json.incomplete_count @incomplete_count
  json.has_next_page @has_next_page
  json.next_cursor @next_cursor
end
