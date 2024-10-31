# frozen_string_literal: true

class TokenCreationForm
  include ActiveModel::Model

  attr_accessor :payload

  validate :validate_payload_presence

  private

  def validate_payload_presence
    errors.add(:payload, 'must be a non-empty hash') if payload.blank?
  end
end
