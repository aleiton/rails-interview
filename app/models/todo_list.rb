# frozen_string_literal: true

class TodoList < ApplicationRecord
  has_many :todo_items, dependent: :destroy

  validates :name, presence: true

  scope :synced, -> { where.not(external_id: nil) }
  scope :unsynced, -> { where(external_id: nil) }

  def to_param
    name.parameterize
  end

  def self.find_by_slug!(slug)
    all.find { |list| list.name.parameterize == slug } ||
      raise(ActiveRecord::RecordNotFound, "Couldn't find TodoList with slug '#{slug}'")
  end
end