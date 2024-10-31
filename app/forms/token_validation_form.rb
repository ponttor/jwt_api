# frozen_string_literal: true

class TokenValidationForm
  include ActiveModel::Model

  attr_accessor :token

  validates :token, presence: true, format: { with: /\A[\w-]+\.[\w-]+\.[\w-]+\z/, message: 'is not in a valid JWT format' }
end
