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

  describe '#to_param (slug)' do
    it 'returns a parameterized version of the name' do
      todo_list = TodoList.new(name: 'Grocery Shopping')

      expect(todo_list.to_param).to eq('grocery-shopping')
    end

    it 'handles special characters' do
      todo_list = TodoList.new(name: 'Work & Life --- Balance!')

      expect(todo_list.to_param).to eq('work-life-balance')
    end
  end

  describe '.find_by_slug!' do
    it 'finds a list by its slug' do
      todo_list = TodoList.create!(name: 'Grocery Shopping')

      expect(TodoList.find_by_slug!('grocery-shopping')).to eq(todo_list)
    end

    it 'raises RecordNotFound for unknown slugs' do
      expect { TodoList.find_by_slug!('nonexistent') }.to raise_error(ActiveRecord::RecordNotFound)
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
