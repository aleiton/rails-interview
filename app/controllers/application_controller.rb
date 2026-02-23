# frozen_string_literal: true

class ApplicationController < ActionController::Base
  rescue_from ActionController::UnknownFormat, with: :raise_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def raise_not_found
    raise ActionController::RoutingError, 'Not supported format'
  end

  def record_not_found
    respond_to do |format|
      format.json { render json: { errors: ['Record not found'] }, status: :not_found }
      format.html { render 'errors/not_found', status: :not_found, layout: 'application' }
      format.turbo_stream { head :not_found }
    end
  end

  def bad_request(exception)
    respond_to do |format|
      format.json { render json: { errors: [exception.message] }, status: :bad_request }
      format.html { redirect_to root_path, alert: exception.message }
      format.turbo_stream { head :bad_request }
    end
  end
end
