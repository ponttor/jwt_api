# frozen_string_literal: true

class JwtService
  ALGORITHM = 'HS256'
  EXPIRATION_TIME = 30.seconds
  JWT_SECRET = ENV['JWT_SECRET']

  class << self
    def encode(payload, exp = EXPIRATION_TIME.from_now)
      payload[:exp] = exp.to_i
      payload[:jti] = SecureRandom.uuid

      JWT.encode(payload, JWT_SECRET, ALGORITHM)
    end

    def decode(token)
      body = JWT.decode(token, JWT_SECRET, true, algorithm: ALGORITHM)[0]

      ActiveSupport::HashWithIndifferentAccess.new(body)
    end
  end
end
