# frozen_string_literal: true

require 'test_helper'

class TokenServiceTest < ActiveSupport::TestCase
  setup do
    @payload = { key: 'test_key', value: 'test_value' }
    @valid_token = JwtService.encode(@payload)
    @expired_token = JwtService.encode(@payload, 5.seconds.ago)
  end

  test 'should create token with valid payload' do
    service = TokenService.new
    token = service.create_token(@payload)

    assert_not_nil token
    decoded_token = JwtService.decode(token)
    assert_equal @payload[:key], decoded_token['key']
    assert_equal @payload[:value], decoded_token['value']
  end

  test 'should raise error for invalid payload on token creation' do
    service = TokenService.new

    assert_raises(TokenCreationForm::PayloadError) do
      service.create_token(nil)
    end
  end

  test 'should decode valid token' do
    service = TokenService.new(@valid_token)
    decoded_token = service.decode_token

    assert_equal @payload[:key], decoded_token['key']
    assert_equal @payload[:value], decoded_token['value']
  end

  test 'should raise error for invalid token format' do
    service = TokenService.new('invalid.token.format')

    assert_raises(JWT::DecodeError) do
      service.decode_token
    end
  end

  test 'should raise error for expired token' do
    service = TokenService.new(@expired_token)

    assert_raises(JWT::ExpiredSignature) do
      service.decode_token
    end
  end

  test 'should renew token' do
    service = TokenService.new(@valid_token)
    new_token = service.renew_token

    assert_not_nil new_token
    assert_not_equal @valid_token, new_token

    decoded_new_token = JwtService.decode(new_token)
    assert_equal @payload[:key], decoded_new_token['key']
    assert_equal @payload[:value], decoded_new_token['value']
    assert decoded_new_token['exp'] > Time.now.to_i
  end

  test 'should invalidate token' do
    service = TokenService.new(@valid_token)
    decoded_token = JwtService.decode(@valid_token)
    token_id = decoded_token[:jti]

    assert_nil Rails.cache.read("invalid_token:#{token_id}")

    service.invalidate_token

    assert Rails.cache.read("invalid_token:#{token_id}")
  end

  test 'should raise error if token is invalidated' do
    decoded_token = JwtService.decode(@valid_token)
    token_id = decoded_token[:jti]
    Rails.cache.write("invalid_token:#{token_id}", true, expires_in: JwtService::EXPIRATION_TIME)

    service = TokenService.new(@valid_token)

    assert_raises(JWT::ExpiredSignature) do
      service.decode_token
    end
  end
end
