require 'rails_helper'

describe Api::TodoItemsController do
  render_views

  describe 'GET index' do
    let(:todo_list) { TodoList.create!(name: 'Test List') }
    let!(:todo_item) { TodoItem.create!(description: 'Do dishes', completed: false, todo_list: todo_list) }

    it 'returns a success code' do
      get :index, params: { todo_list_id: todo_list.id }, format: :json

      expect(response.status).to eq(200)
    end

    it 'includes todo item records' do
      get :index, params: { todo_list_id: todo_list.id }, format: :json

      expect(response.content_type).to include('application/json')
      expect(response.body).to eq([{
        id: todo_item.id,
        description: 'Do dishes',
        completed: false,
        todo_list_id: todo_list.id,
        created_at: todo_item.created_at.as_json,
        updated_at: todo_item.updated_at.as_json
      }].to_json)
    end
  end
end
