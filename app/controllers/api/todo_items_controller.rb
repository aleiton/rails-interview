module Api
  class TodoItemsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :set_todo_list
    before_action :set_todo_item, only: %i[show update destroy]

    # GET /api/todolists/:todo_list_id/todoitems
    def index
      @todo_items = @todo_list.todo_items

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
          format.json { render :show, status: :ok }
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
