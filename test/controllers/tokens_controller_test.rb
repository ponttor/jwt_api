# frozen_string_literal: true

require 'test_helper'

class TokensControllerTest < ActionDispatch::IntegrationTest
  test 'should create token' do
    token_params = { payload: { key: 'test_key', value: 'test_value' } }

    post tokens_url, params: { token: token_params }, as: :json

    assert_response :success

    json_response = response.parsed_body
    decoded_token = JwtService.decode(json_response['token'])

    assert_equal 'test_key', decoded_token['key']
    assert_equal 'test_value', decoded_token['value']
  end

  test 'should create token as QR code' do
    token_params = { payload: { key: 'test_key', value: 'test_value' } }

    post tokens_url, params: { token: token_params, format: 'qr' }

    assert_response :success

    assert_equal 'image/png', @response.media_type
    assert @response.body.present?
    assert_equal Encoding::BINARY, @response.body.encoding
  end

  test 'should not create token without payload' do
    post tokens_url, params: { token: { payload: nil } }, as: :json

    assert_response :unprocessable_entity

    json_response = response.parsed_body
    assert_equal 'Payload must be a non-empty hash', json_response['error']
  end

  test 'should not create token if payload is not a hash' do
    token_params = { payload: 'string_instead_of_hash' }

    post tokens_url, params: { token: token_params }, as: :json

    assert_response :unprocessable_entity

    json_response = response.parsed_body
    assert_equal 'Payload must be a non-empty hash', json_response['error']
  end

  test 'should not create token without token param' do
    post tokens_url, params: {}, as: :json

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal 'param is missing or the value is empty: token', json_response['error']
  end

  test 'should not create token if payload is an empty hash' do
    token_params = { payload: {} }

    post tokens_url, params: { token: token_params }, as: :json

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal 'Payload must be a non-empty hash', json_response['error']
  end

  test 'should validate token' do
    token = JwtService.encode({ key: 'test_key', value: 'test_value' })

    get validate_tokens_url, params: { token: token }

    assert_response :success

    json_response = response.parsed_body
    assert_equal 'Token is valid', json_response['message']
  end

  test 'should not validate invalid token not enough segments' do
    get validate_tokens_url, params: { token: 'invalid_token' }

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal 'Token is not in a valid JWT format', json_response['error']
  end

  test 'should not validate invalid token is empty' do
    get validate_tokens_url, params: {}

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal "Token can't be blank, Token is not in a valid JWT format", json_response['error']
  end

  test 'should not validate expired token' do
    token = JwtService.encode({ key: 'test_key', value: 'test_value' }, 5.seconds.ago)

    get validate_tokens_url, params: { token: token }

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal 'Signature has expired', json_response['error']
  end

  test 'should not validate invalid token Invalid segment encoding' do
    get validate_tokens_url, params: { token: 'invalid_token.invalid.token' }

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal 'Invalid segment encoding', json_response['error']
  end

  test 'should not validate token with invalid signature' do
    token = JWT.encode({ key: 'test_key', value: 'test_value' }, 'wrong_secret', 'HS256')

    get validate_tokens_url, params: { token: token }

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal 'Signature verification failed', json_response['error']
  end

  test 'should validate token with future expiration' do
    token = JwtService.encode({ key: 'test_key', value: 'test_value' }, 10.minutes.from_now)

    get validate_tokens_url, params: { token: token }

    assert_response :success
    json_response = response.parsed_body
    assert_equal 'Token is valid', json_response['message']
  end

  test 'should not validate token without exp claim' do
    token = JWT.encode({ key: 'test_key', value: 'test_value' }, JwtService::JWT_SECRET, 'HS512')

    get validate_tokens_url, params: { token: token }

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal 'Expected a different algorithm', json_response['error']
  end

  test 'should delete (invalidate) token' do
    token = JwtService.encode({ key: 'test_key', value: 'test_value' })
    # byebug
    delete tokens_url, params: { token: token }, as: :json
    assert_response :no_content

    get validate_tokens_url, params: { token: token }

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal 'Token has been invalidated', json_response['error']
  end

  test 'should not delete invalid token' do
    invalid_token = 'invalid.token.format'

    delete tokens_url, params: { token: invalid_token }, as: :json

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal 'Invalid segment encoding', json_response['error']
  end

  test 'should not delete invalid format token' do
    invalid_token = 'invalid.format'

    delete tokens_url, params: { token: invalid_token }, as: :json

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal 'Token is not in a valid JWT format', json_response['error']
  end

  test 'should not delete already expired token' do
    expired_token = JwtService.encode({ key: 'test_key', value: 'test_value' }, 5.seconds.ago)

    delete tokens_url, params: { token: expired_token }, as: :json

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal 'Signature has expired', json_response['error']
  end

  test 'should not delete token if token is missing' do
    delete tokens_url, params: {}, as: :json

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal "Token can't be blank, Token is not in a valid JWT format", json_response['error']
  end

  test 'should not validate invalidated token' do
    token = JwtService.encode({ key: 'test_key', value: 'test_value' })

    decoded_token = JwtService.decode(token)
    token_id = decoded_token[:jti]

    Rails.cache.write("invalid_token:#{token_id}", true, expires_in: JwtService::EXPIRATION_TIME)

    get validate_tokens_url, params: { token: token }

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal 'Token has been invalidated', json_response['error']
  end

  test 'should renew token' do
    token = JwtService.encode({ key: 'test_key', value: 'test_value' }, 10.seconds.from_now)

    post renew_tokens_url, params: { token: token }, as: :json

    assert_response :success

    json_response = response.parsed_body
    new_token = json_response['token']

    assert_not_equal token, new_token

    decoded_new_token = JwtService.decode(new_token)
    assert_equal 'test_key', decoded_new_token['key']
    assert_equal 'test_value', decoded_new_token['value']

    assert decoded_new_token['exp'] > Time.now.to_i
  end

  test 'should not renew expired token' do
    token = JwtService.encode({ key: 'test_key', value: 'test_value' }, 5.seconds.ago)

    post renew_tokens_url, params: { token: token }, as: :json

    assert_response :unprocessable_entity

    json_response = response.parsed_body
    assert_equal 'Signature has expired', json_response['error']
  end

  test 'should handle invalid token in renew' do
    post renew_tokens_url, params: { token: 'invalid_token' }, as: :json

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal 'Token is not in a valid JWT format', json_response['error']
  end

  test 'should not renew without token parameter' do
    post renew_tokens_url, params: {}, as: :json

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal "Token can't be blank, Token is not in a valid JWT format", json_response['error']
  end

  test 'should not renew invalidated token' do
    token = JwtService.encode({ key: 'test_key', value: 'test_value' })

    decoded_token = JwtService.decode(token)
    token_id = decoded_token[:jti]
    Rails.cache.write("invalid_token:#{token_id}", true, expires_in: JwtService::EXPIRATION_TIME)

    post renew_tokens_url, params: { token: token }, as: :json

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal 'Token has been invalidated', json_response['error']
  end

  test 'should renew token as QR code' do
    token = JwtService.encode({ key: 'test_key', value: 'test_value' }, 10.minutes.from_now)

    post renew_tokens_url, params: { token: token, format: 'qr' }, as: :json

    assert_response :success

    assert_equal 'image/png', @response.media_type

    assert @response.body.present?
    assert_equal Encoding::BINARY, @response.body.encoding
  end
end
