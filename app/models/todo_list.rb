# frozen_string_literal: true

class TodoList < ApplicationRecord
  has_many :todo_items, dependent: :destroy

  validates :name, presence: true

  scope :synced, -> { where.not(external_id: nil) }
  scope :unsynced, -> { where(external_id: nil) }
end