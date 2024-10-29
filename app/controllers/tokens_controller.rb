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
  rescue StandardError => e
    handle_error(e, action: 'Creation')
  end

  def validate
    TokenService.new(token_param).decode_token

    render json: { message: 'Token is valid' }, status: :ok
  rescue StandardError => e
    handle_error(e, action: 'Validate')
  end

  def renew
    new_token = TokenService.new(token_param).renew_token

    return send_qr_code_response(new_token) if params[:format] == 'qr'

    render json: { token: new_token, message: 'Token renewed successfully' }
  rescue StandardError => e
    handle_error(e, action: 'Renew')
  end

  def destroy
    TokenService.new(token_param).invalidate_token

    head :no_content
  rescue StandardError => e
    handle_error(e, action: 'Delete')
  end

  private

  def token_param
    params.require(:token)
  end

  def token_params
    params.require(:token).permit(payload: {})
  end

  def send_qr_code_response(token)
    qr_code_png = QrCodeService.generate_png(token)
    send_data qr_code_png, type: 'image/png', disposition: 'inline'
  end
end
