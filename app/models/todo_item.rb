# frozen_string_literal: true

class TodoItem < ApplicationRecord
  belongs_to :todo_list

  validates :description, length: { minimum: 5 }
end
