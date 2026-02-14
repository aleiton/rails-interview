# frozen_string_literal: true

require 'rails_helper'

describe Api::TodoItemsController do
  render_views

  let(:todo_list) { TodoList.create!(name: 'Test List') }

  describe 'GET index' do
    let!(:todo_item) { TodoItem.create!(description: 'Do dishes', completed: false, todo_list: todo_list) }

    it 'returns the todo items as JSON' do
      get :index, params: { todo_list_id: todo_list.id }, format: :json

      expect(response.status).to eq(200)
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

    context 'when the todo list does not exist' do
      it 'returns a 404 with error message' do
        get :index, params: { todo_list_id: 0 }, format: :json

        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['error']).to eq('Record not found')
      end
    end
  end

  describe 'POST create' do
    context 'with valid parameters' do
      let(:valid_params) do
        { todo_list_id: todo_list.id, todo_item: { description: 'Buy groceries', completed: false } }
      end

      it 'creates the todo item and returns it' do
        post :create, params: valid_params, format: :json

        expect(response.status).to eq(201)

        body = JSON.parse(response.body)

        expect(body['description']).to eq('Buy groceries')
        expect(body['completed']).to eq(false)
        expect(body['todo_list_id']).to eq(todo_list.id)
      end

      it 'persists the new todo item' do
        expect do
          post :create, params: valid_params, format: :json
        end.to change(todo_list.todo_items, :count).by(1)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        { todo_list_id: todo_list.id, todo_item: { description: '', completed: false } }
      end

      it 'returns a 422 with error messages' do
        post :create, params: invalid_params, format: :json

        expect(response.status).to eq(422)

        body = JSON.parse(response.body)

        expect(body['errors']).to include('Description is too short (minimum is 5 characters)')
      end

      it 'returns a 400 when todo_item key is missing' do
        post :create, params: { todo_list_id: todo_list.id }, format: :json

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)['error']).to include('todo_item')
      end

      it 'does not persist the todo item' do
        expect do
          post :create, params: invalid_params, format: :json
        end.not_to change(TodoItem, :count)
      end
    end
  end

  describe 'PATCH update' do
    let!(:todo_item) { TodoItem.create!(description: 'Do dishes', completed: false, todo_list: todo_list) }

    context 'with valid parameters' do
      it 'updates the todo item and returns it' do
        patch :update,
              params: { todo_list_id: todo_list.id, id: todo_item.id,
                        todo_item: { description: 'Do laundry', completed: true } },
              format: :json

        expect(response.status).to eq(200)

        body = JSON.parse(response.body)

        expect(body['description']).to eq('Do laundry')
        expect(body['completed']).to eq(true)
      end
    end

    context 'with invalid parameters' do
      it 'returns a 422 with error messages' do
        patch :update,
              params: { todo_list_id: todo_list.id, id: todo_item.id,
                        todo_item: { description: '' } },
              format: :json

        expect(response.status).to eq(422)

        body = JSON.parse(response.body)

        expect(body['errors']).to include('Description is too short (minimum is 5 characters)')
      end
    end

    context 'when the todo item does not exist' do
      it 'returns a 404 with error message' do
        patch :update,
              params: { todo_list_id: todo_list.id, id: 0,
                        todo_item: { description: 'Nope' } },
              format: :json

        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['error']).to eq('Record not found')
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:todo_item) { TodoItem.create!(description: 'Do dishes', completed: false, todo_list: todo_list) }

    context 'with an existing todo item' do
      it 'returns a 204 status' do
        delete :destroy, params: { todo_list_id: todo_list.id, id: todo_item.id }, format: :json

        expect(response.status).to eq(204)
      end

      it 'removes the todo item' do
        expect do
          delete :destroy, params: { todo_list_id: todo_list.id, id: todo_item.id }, format: :json
        end.to change(todo_list.todo_items, :count).by(-1)
      end
    end

    context 'when the todo item does not exist' do
      it 'returns a 404 with error message' do
        delete :destroy, params: { todo_list_id: todo_list.id, id: 0 }, format: :json

        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['error']).to eq('Record not found')
      end
    end
  end
end
