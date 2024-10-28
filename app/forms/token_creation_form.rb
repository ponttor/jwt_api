# frozen_string_literal: true

class TokenCreationForm
  include ActiveModel::Model

  class PayloadError < StandardError; end

  attr_accessor :payload

  validate :validate_payload_presence

  def normalized
    payload.to_h
  end

  private

  def validate_payload_presence
    raise TokenCreationForm::PayloadError, 'Payload must be a non-empty hash' if payload.blank?
  end
end
