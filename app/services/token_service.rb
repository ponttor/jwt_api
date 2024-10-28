# frozen_string_literal: true

class TokenService
  class TokenValidationError < StandardError; end

  def initialize(token = nil)
    @token = token
  end

  def create_token(payload)
    form = TokenCreationForm.new(payload: payload)
    raise TokenCreationForm::PayloadError, 'Invalid payload' unless form.valid?

    JwtService.encode(form.normalized)
  end

  def decode_token
    validate_token_format

    decoded_token = JwtService.decode(@token)
    raise JWT::ExpiredSignature, 'Token has been invalidated' if token_invalidated?(decoded_token[:jti])

    decoded_token
  end

  def renew_token
    decoded_token = decode_token
    JwtService.encode(decoded_token.except(:exp))
  end

  def invalidate_token
    decoded_token = decode_token
    token_id = decoded_token[:jti]
    Rails.cache.write("invalid_token:#{token_id}", true, expires_in: JwtService::EXPIRATION_TIME)
  end

  private

  def validate_token_format
    form = TokenValidationForm.new(token: @token)
    return if form.valid?

    raise TokenValidationError, form.errors.full_messages.join(', ')
  end

  def token_invalidated?(token_id)
    Rails.cache.read("invalid_token:#{token_id}").present?
  end
end
