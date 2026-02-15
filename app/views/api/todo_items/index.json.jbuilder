json.items @todo_items, :id, :description, :completed, :todo_list_id, :created_at, :updated_at

json.meta do
  json.page @page
  json.per_page @per_page
  json.total_count @total_count
  json.total_pages @total_pages
end
