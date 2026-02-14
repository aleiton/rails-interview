# frozen_string_literal: true

require 'rails_helper'

describe Api::TodoListsController do
  render_views

  describe 'GET index' do
    let!(:todo_list) { TodoList.create!(name: 'Setup RoR project') }

    it 'returns the todo lists as JSON' do
      get :index, format: :json

      expect(response.status).to eq(200)

      todo_lists = JSON.parse(response.body)

      expect(todo_lists.count).to eq(1)
      expect(todo_lists[0]['id']).to eq(todo_list.id)
      expect(todo_lists[0]['name']).to eq(todo_list.name)
    end
  end

  describe 'GET show' do
    let!(:todo_list) { TodoList.create!(name: 'Shopping List') }

    it 'returns the todo list as JSON' do
      get :show, params: { id: todo_list.id }, format: :json

      expect(response.status).to eq(200)

      body = JSON.parse(response.body)

      expect(body['id']).to eq(todo_list.id)
      expect(body['name']).to eq('Shopping List')
    end

    context 'when the todo list does not exist' do
      it 'returns a 404 with error message' do
        get :show, params: { id: 0 }, format: :json

        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['errors']).to include('Record not found')
      end
    end
  end

  describe 'POST create' do
    context 'with valid parameters' do
      it 'creates the todo list and returns it' do
        post :create, params: { todo_list: { name: 'New List' } }, format: :json

        expect(response.status).to eq(201)

        body = JSON.parse(response.body)

        expect(body['name']).to eq('New List')
      end

      it 'persists the new todo list' do
        expect do
          post :create, params: { todo_list: { name: 'New List' } }, format: :json
        end.to change(TodoList, :count).by(1)
      end
    end

    context 'with invalid parameters' do
      it 'returns a 422 with error messages' do
        post :create, params: { todo_list: { name: '' } }, format: :json

        expect(response.status).to eq(422)

        body = JSON.parse(response.body)

        expect(body['errors']).to include("Name can't be blank")
      end

      it 'returns a 400 when todo_list key is missing' do
        post :create, params: {}, format: :json

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)['errors'].first).to include('todo_list')
      end

      it 'does not persist the todo list' do
        expect do
          post :create, params: { todo_list: { name: '' } }, format: :json
        end.not_to change(TodoList, :count)
      end
    end
  end

  describe 'PATCH update' do
    let!(:todo_list) { TodoList.create!(name: 'Old Name') }

    context 'with valid parameters' do
      it 'updates the todo list and returns it' do
        patch :update, params: { id: todo_list.id, todo_list: { name: 'New Name' } }, format: :json

        expect(response.status).to eq(200)

        body = JSON.parse(response.body)

        expect(body['name']).to eq('New Name')
      end
    end

    context 'with invalid parameters' do
      it 'returns a 422 with error messages' do
        patch :update, params: { id: todo_list.id, todo_list: { name: '' } }, format: :json

        expect(response.status).to eq(422)

        body = JSON.parse(response.body)

        expect(body['errors']).to include("Name can't be blank")
      end
    end

    context 'when the todo list does not exist' do
      it 'returns a 404 with error message' do
        patch :update, params: { id: 0, todo_list: { name: 'Nope' } }, format: :json

        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['errors']).to include('Record not found')
      end
    end
  end

  describe 'POST complete_all' do
    include ActiveJob::TestHelper

    let!(:todo_list) { TodoList.create!(name: 'Bulk Complete') }

    it 'returns 202 and enqueues a CompleteAllItemsJob' do
      expect do
        post :complete_all, params: { id: todo_list.id }, format: :json
      end.to have_enqueued_job(CompleteAllItemsJob).with(todo_list.id)

      expect(response.status).to eq(202)
    end

    context 'when the todo list does not exist' do
      it 'returns a 404 with error message' do
        post :complete_all, params: { id: 0 }, format: :json

        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['errors']).to include('Record not found')
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:todo_list) { TodoList.create!(name: 'To Delete') }

    context 'with an existing todo list' do
      it 'returns a 204 status' do
        delete :destroy, params: { id: todo_list.id }, format: :json

        expect(response.status).to eq(204)
      end

      it 'removes the todo list' do
        expect do
          delete :destroy, params: { id: todo_list.id }, format: :json
        end.to change(TodoList, :count).by(-1)
      end
    end

    context 'when the todo list does not exist' do
      it 'returns a 404 with error message' do
        delete :destroy, params: { id: 0 }, format: :json

        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['errors']).to include('Record not found')
      end
    end
  end
end
