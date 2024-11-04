# frozen_string_literal: true

require 'test_helper'

class JwtServiceTest < ActiveSupport::TestCase
  def setup
    @payload = { user_id: 1, role: 'admin' }
  end

  test 'encode generates a valid JWT token with default expiration' do
    token = JwtService.encode(@payload)
    decoded_payload = JwtService.decode(token)

    assert_equal @payload[:user_id], decoded_payload[:user_id]
    assert_equal @payload[:role], decoded_payload[:role]
    assert decoded_payload[:exp] > Time.now.to_i
  end

  test 'encode raises an error for invalid payload' do
    assert_raises(TypeError) do
      JwtService.encode('invalid.token.here')
    end
  end

  test 'decode returns the correct payload for a valid token' do
    token = JwtService.encode(@payload)
    decoded_payload = JwtService.decode(token)

    assert_equal @payload[:user_id], decoded_payload[:user_id]
    assert_equal @payload[:role], decoded_payload[:role]
  end

  test 'invalidate creates an expired token' do
    expired_token = JwtService.encode(@payload, 1.minute.ago)

    assert_raises(JWT::ExpiredSignature) do
      JwtService.decode(expired_token)
    end
  end

  test 'decode raises an error for invalid token' do
    assert_raises(JWT::DecodeError) do
      JwtService.decode('invalid.token.here')
    end
  end
end
