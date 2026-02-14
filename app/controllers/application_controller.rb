class ApplicationController < ActionController::Base
  rescue_from ActionController::UnknownFormat, with: :raise_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def raise_not_found
    raise ActionController::RoutingError.new('Not supported format')
  end

  def record_not_found
    render json: { errors: ['Record not found'] }, status: :not_found
  end

  def bad_request(exception)
    render json: { errors: [exception.message] }, status: :bad_request
  end
end
