require 'rails_helper'

RSpec.describe TodoItem, type: :model do
  let(:todo_list) { TodoList.create!(name: 'Test List') }
  let(:todo_item) { todo_list.todo_items.build(description: 'Do dishes', completed: false) }

  describe 'validations' do
    it 'is valid with a description' do
      expect(todo_item).to be_valid
    end

    it 'is invalid without a description' do
      todo_item.description = nil

      expect(todo_item).not_to be_valid
      expect(todo_item.errors[:description]).to include("can't be blank")
    end
  end
end
