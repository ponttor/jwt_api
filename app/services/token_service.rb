# frozen_string_literal: true

class TokenService
  class TokenPayloadError < StandardError; end

  def initialize(token = nil)
    @token = token
  end

  def create_token(payload)
    validate_payload(payload)
    JwtService.encode(payload)
  end

  def valid_token?
    validate_token_format
    decoded_token = decode_token
    !token_invalidated?(decoded_token[:jti])
  end

  def decode_and_validate_token
    validate_token_format
    decoded_token = decode_token
    validate_token_id(decoded_token[:jti])

    decoded_token
  end

  def renew_token
    decoded_token = decode_and_validate_token
    JwtService.encode(decoded_token.except(:exp))
  end

  def invalidate_token
    decoded_token = decode_and_validate_token
    token_id = decoded_token[:jti]
    invalidate_token_id(token_id)
  end

  private

  def validate_payload(payload)
    form = TokenCreationForm.new(payload: payload)
    raise TokenPayloadError, form.errors.full_messages.join(', ') unless form.valid?
  end

  def validate_token_format
    form = TokenValidationForm.new(token: @token)
    raise TokenPayloadError, form.errors.full_messages.join(', ') unless form.valid?
  end

  def decode_token
    JwtService.decode(@token)
  end

  def validate_token_id(token_id)
    raise TokenPayloadError, 'Token has been invalidated' if token_invalidated?(token_id)
  end

  def invalidate_token_id(token_id)
    Rails.cache.write("invalid_token:#{token_id}", true, expires_in: JwtService::EXPIRATION_TIME)
  end

  def token_invalidated?(token_id)
    Rails.cache.read("invalid_token:#{token_id}").present?
  end
end
