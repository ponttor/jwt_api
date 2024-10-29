# frozen_string_literal: true

class TokensController < ApplicationController
  rate_limit to: 100, within: 1.minute, store: Rails.cache

  def create
    form = TokenCreationForm.new(token_params)

    if form.valid?
      token = JwtService.encode(form.normalized)
      return send_qr_code_response(token) if params[:format] == 'qr'

      render json: { token: token, message: 'Token has been generated' }
    end
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  rescue TokenCreationForm::PayloadError, JWT::EncodeError, TypeError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: "Creation error: #{e.message}" }, status: :internal_server_error
  end

  def validate
    TokenService.new(params[:token]).decode_token

    render json: { message: 'Token is valid' }, status: :ok
  rescue TokenService::TokenValidationError => e
    render json: { error: e.message }, status: :bad_request
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: "Validation error: #{e.message}" }, status: :internal_server_error
  end

  def renew
    new_token = TokenService.new(params[:token]).renew_token

    return send_qr_code_response(new_token) if params[:format] == 'qr'

    render json: { token: new_token, message: 'Token renewed successfully' }
  rescue TokenService::TokenValidationError => e
    render json: { error: e.message }, status: :bad_request
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: "Renewing error: #{e.message}" }, status: :internal_server_error
  end

  def destroy
    TokenService.new(params[:token]).invalidate_token

    head :no_content
  rescue TokenService::TokenValidationError => e
    render json: { error: e.message }, status: :bad_request
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: "Delete error: #{e.message}" }, status: :internal_server_error
  end

  private

  def token_params
    params.require(:token).permit(payload: {})
  end

  def send_qr_code_response(token)
    qr_code_png = QrCodeService.generate_png(token)
    send_data qr_code_png, type: 'image/png', disposition: 'inline'
  end
end
