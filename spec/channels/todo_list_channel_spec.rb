require "rails_helper"

RSpec.describe TodoListChannel, type: :channel do
  let(:todo_list) { TodoList.create!(name: "Test List") }

  it "subscribes to a valid todo list" do
    subscribe(id: todo_list.id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("todo_list_#{todo_list.id}")
  end

  it "rejects subscription for a non-existent todo list" do
    subscribe(id: 999_999)

    expect(subscription).to be_rejected
  end
end
