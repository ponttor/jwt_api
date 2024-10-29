# frozen_string_literal: true

require 'test_helper'

class QrCodeServiceTest < ActiveSupport::TestCase
  def setup
    @token = 'test_token'
  end

  test 'should generate SVG QR code' do
    svg_code = QrCodeService.generate_svg(@token)

    assert_not_nil svg_code
    assert_match(/<svg/, svg_code)
    assert_match(%r{</svg>}, svg_code)
    assert_match(/<path/, svg_code)
  end

  test 'should convert SVG to PNG' do
    svg_code = QrCodeService.generate_svg(@token)
    png_data = QrCodeService.convert_svg_to_png(svg_code)

    assert_not_nil png_data
    assert png_data.is_a?(String)
    assert_equal 'PNG', png_data[1..3]
  end

  test 'should generate PNG QR code from token' do
    png_data = QrCodeService.generate_png(@token)

    assert_not_nil png_data
    assert png_data.is_a?(String)
    assert_equal 'PNG', png_data[1..3]
  end

  test 'should raise error if SVG conversion to PNG fails' do
    invalid_svg_code = '<svg><invalid_tag></invalid_tag></svg>'

    error = assert_raises(StandardError) do
      QrCodeService.convert_svg_to_png(invalid_svg_code)
    end

    assert_equal 'Failed to convert SVG to PNG', error.message
  end
end
