# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TodoItem, type: :model do
  let(:todo_list) { TodoList.create!(name: 'Test List') }
  let(:todo_item) { todo_list.todo_items.build(description: 'Do dishes', completed: false) }

  describe 'validations' do
    it 'is valid with a description of 5 or more characters' do
      expect(todo_item).to be_valid
    end

    it 'is invalid without a description' do
      todo_item.description = nil

      expect(todo_item).not_to be_valid
      expect(todo_item.errors[:description]).to include('is too short (minimum is 5 characters)')
    end

    it 'is invalid with a description shorter than 5 characters' do
      todo_item.description = 'ab'

      expect(todo_item).not_to be_valid
      expect(todo_item.errors[:description]).to include('is too short (minimum is 5 characters)')
    end
  end
end
