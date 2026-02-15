# frozen_string_literal: true

class TodoListsController < ApplicationController
  before_action :set_todo_list, only: %i[show edit update destroy complete_all]

  def index
    @todo_lists = TodoList.order(:name)
    @todo_list = @todo_lists.first
  end

  def show
    @todo_lists = TodoList.order(:name)
  end

  def new
    @todo_lists = TodoList.order(:name)
    @todo_list = TodoList.new
  end

  def create
    @todo_list = TodoList.new(todo_list_params)

    if @todo_list.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @todo_list }
      end
    else
      @todo_lists = TodoList.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @todo_lists = TodoList.order(:name)
  end

  def update
    if @todo_list.update(todo_list_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @todo_list }
      end
    else
      @todo_lists = TodoList.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @todo_list.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to todo_lists_path }
    end
  end

  def complete_all
    CompleteAllItemsJob.perform_later(@todo_list.id)
    redirect_to @todo_list, notice: "Completing all items..."
  end

  private

  def set_todo_list
    @todo_list = TodoList.find_by_slug!(params[:id])
  end

  def todo_list_params
    params.require(:todo_list).permit(:name)
  end
end
