# frozen_string_literal: true

module Api
  class TodoItemsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :set_todo_list
    before_action :set_todo_item, only: %i[update destroy]

    DEFAULT_PER_PAGE = 50
    MAX_PER_PAGE = 100

    # GET /api/todolists/:todo_list_id/todoitems
    def index
      @per_page = [[(params[:per_page] || DEFAULT_PER_PAGE).to_i, 1].max, MAX_PER_PAGE].min

      base_scope = @todo_list.todo_items.order(id: :asc)
      @total_count = base_scope.count
      @incomplete_count = @todo_list.todo_items.where(completed: false).count

      scope = params[:after_id].present? ? base_scope.where("id > ?", params[:after_id].to_i) : base_scope
      all_items = scope.limit(@per_page + 1).to_a
      @has_next_page = all_items.length > @per_page
      @todo_items = all_items.first(@per_page)
      @next_cursor = @todo_items.last&.id

      respond_to :json
    end

    # POST /api/todolists/:todo_list_id/todoitems
    def create
      @todo_item = @todo_list.todo_items.build(todo_item_params)

      if @todo_item.save
        respond_to do |format|
          format.json { render :show, status: :created }
        end
      else
        respond_to do |format|
          format.json { render json: { errors: @todo_item.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /api/todolists/:todo_list_id/todoitems/:id
    def update
      if @todo_item.update(todo_item_params)
        respond_to do |format|
          format.json { render :show }
        end
      else
        respond_to do |format|
          format.json { render json: { errors: @todo_item.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /api/todolists/:todo_list_id/todoitems/:id
    def destroy
      @todo_item.destroy

      head :no_content
    end

    private

    def set_todo_list
      @todo_list = TodoList.find(params[:todo_list_id])
    end

    def set_todo_item
      @todo_item = @todo_list.todo_items.find(params[:id])
    end

    def todo_item_params
      params.require(:todo_item).permit(:description, :completed)
    end
  end
end
