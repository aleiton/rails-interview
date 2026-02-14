class TodoListChannel < ApplicationCable::Channel
  def subscribed
    todo_list = TodoList.find_by(id: params[:id])

    if todo_list
      stream_from "todo_list_#{params[:id]}"
    else
      reject
    end
  end
end
