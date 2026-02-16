# frozen_string_literal: true

class TodoItem < ApplicationRecord
  belongs_to :todo_list

  validates :description, presence: true, length: { minimum: 5 }

  scope :synced, -> { where.not(external_id: nil) }
  scope :unsynced, -> { where(external_id: nil) }
end
