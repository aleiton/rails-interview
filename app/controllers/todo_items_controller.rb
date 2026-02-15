# frozen_string_literal: true

class TodoItemsController < ApplicationController
  before_action :set_todo_list
  before_action :set_todo_item, only: %i[update destroy toggle]

  def create
    @todo_item = @todo_list.todo_items.new(todo_item_params)

    if @todo_item.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @todo_list }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("new_item_form",
            partial: "todo_items/form_with_errors",
            locals: { todo_list: @todo_list, todo_item: @todo_item })
        end
        format.html { redirect_to @todo_list, alert: @todo_item.errors.full_messages.join(", ") }
      end
    end
  end

  def update
    if @todo_item.update(todo_item_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @todo_list }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@todo_item),
            partial: "todo_items/todo_item",
            locals: { todo_item: @todo_item })
        end
        format.html { redirect_to @todo_list, alert: @todo_item.errors.full_messages.join(", ") }
      end
    end
  end

  def destroy
    @todo_item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @todo_list }
    end
  end

  def toggle
    @todo_item.update!(completed: !@todo_item.completed)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @todo_list }
    end
  end

  private

  def set_todo_list
    @todo_list = TodoList.find_by_slug!(params[:todo_list_id])
  end

  def set_todo_item
    @todo_item = @todo_list.todo_items.find(params[:id])
  end

  def todo_item_params
    params.require(:todo_item).permit(:description, :completed)
  end
end
