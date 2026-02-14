# frozen_string_literal: true

module Api
  class TodoListsController < ApplicationController
    skip_before_action :verify_authenticity_token

    before_action :set_todo_list, only: %i[show update destroy]

    # GET /api/todolists
    def index
      @todo_lists = TodoList.all

      respond_to :json
    end

    # GET /api/todolists/:id
    def show
      respond_to :json
    end

    # POST /api/todolists
    def create
      @todo_list = TodoList.new(todo_list_params)

      if @todo_list.save
        respond_to do |format|
          format.json { render :show, status: :created }
        end
      else
        respond_to do |format|
          format.json { render json: { errors: @todo_list.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /api/todolists/:id
    def update
      if @todo_list.update(todo_list_params)
        respond_to do |format|
          format.json { render :show }
        end
      else
        respond_to do |format|
          format.json { render json: { errors: @todo_list.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /api/todolists/:id
    def destroy
      @todo_list.destroy

      head :no_content
    end

    private

    def set_todo_list
      @todo_list = TodoList.find(params[:id])
    end

    def todo_list_params
      params.require(:todo_list).permit(:name)
    end
  end
end
