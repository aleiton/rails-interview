# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      format.html { render :not_found, status: :not_found }
      format.json { render json: { errors: ['Not found'] }, status: :not_found }
    end
  end
end
