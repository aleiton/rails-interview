# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TodoList, type: :model do
  describe 'validations' do
    it 'is valid with a name' do
      todo_list = TodoList.new(name: 'Shopping List')

      expect(todo_list).to be_valid
    end

    it 'is invalid without a name' do
      todo_list = TodoList.new(name: nil)

      expect(todo_list).not_to be_valid
      expect(todo_list.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with a blank name' do
      todo_list = TodoList.new(name: '')

      expect(todo_list).not_to be_valid
      expect(todo_list.errors[:name]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'destroys associated todo items when deleted' do
      todo_list = TodoList.create!(name: 'Test List')
      todo_list.todo_items.create!(description: 'Do dishes', completed: false)

      expect do
        todo_list.destroy
      end.to change(TodoItem, :count).by(-1)
    end
  end
end
