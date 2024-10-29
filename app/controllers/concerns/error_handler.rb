# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  def handle_error(exception, action:)
    case exception
    when ActionController::ParameterMissing
      Rails.logger.warn("#{action} failed: #{exception.message}")
      render json: { error: exception.message }, status: :bad_request
    when JWT::EncodeError, JWT::DecodeError, JWT::ExpiredSignature, TypeError, TokenService::TokenPayloadError
      Rails.logger.error("#{action} unprocessable entity: #{exception.message}")
      render json: { error: exception.message }, status: :unprocessable_entity
    when MiniMagick::Error
      Rails.logger.error("MiniMagick error during #{action}: #{exception.message}")
      render json: { error: 'Failed to generate QR code image' }, status: :unprocessable_entity
    else
      Rails.logger.fatal("#{action} encountered an unexpected error: #{exception.message}")
      render json: { error: "#{action} error: #{exception.message}" }, status: :internal_server_error
    end
  end
end
