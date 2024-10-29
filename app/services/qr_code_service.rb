# frozen_string_literal: true

class QrCodeService
  class << self
    def generate_png(token)
      svg_code = generate_svg(token)
      convert_svg_to_png(svg_code)
    end

    def generate_svg(token)
      qr = RQRCode::QRCode.new(token)
      qr.as_svg(
        module_size: 4,
        standalone: true,
        use_path: true
      )
    end

    def convert_svg_to_png(svg_code)
      image = MiniMagick::Image.read(svg_code) { |img| img.format 'svg' }
      image.format 'png'
      raise StandardError, 'Failed to convert SVG to PNG' unless image.valid?

      image.to_blob
    rescue MiniMagick::Error
      raise StandardError, 'Failed to convert SVG to PNG'
    end
  end
end
