module CHF
  # Generate URLs backed by an pre-generated assets on s3.
  # DZIs, or our new custom style of derivatives created by CreateDerivativesOnS3Service
  #
  # Supports tile_source_url, thumb_url.
  class DziS3UrlService
    attr_reader :file_id, :checksum, :file_set_id
    def initialize(file_set_id:, file_id:, checksum:)
      @file_id = file_id
      @checksum = checksum
      @file_set_id = file_set_id
    end

    def tile_source_url
      CreateDziService.s3_dzi_url_for(file_id: file_id, checksum: checksum)
    end

    def thumb_url(size:, density_descriptor: nil)
      CreateDerivativesOnS3Service.s3_url(file_set_id: file_set_id, file_checksum: checksum, filename_key: size_to_thumbnail_filename_key(size: size, density_descriptor: density_descriptor), suffix: ".jpg")
    end

    # We have 1x and 2x statically generated.
    def thumb_srcset_pixel_density(size:)
      "#{thumb_url(size: size)} 1x, #{thumb_url(size: size, density_descriptor: '2X')} 2x"
    end

    def download_options
      [
        {
          option_key: "small",
          url: CreateDerivativesOnS3Service.s3_url(file_set_id: file_set_id, file_checksum: checksum, filename_key: "dl_small", suffix: ".jpg")
        },
        {
          option_key: "medium",
          url: CreateDerivativesOnS3Service.s3_url(file_set_id: file_set_id, file_checksum: checksum, filename_key: "dl_medium", suffix: ".jpg")
        },
        {
          option_key: "large",
          url: CreateDerivativesOnS3Service.s3_url(file_set_id: file_set_id, file_checksum: checksum, filename_key: "dl_large", suffix: ".jpg")
        },
        {
          option_key: "full",
          url: CreateDerivativesOnS3Service.s3_url(file_set_id: file_set_id, file_checksum: checksum, filename_key: "dl_full_size", suffix: ".jpg")
        }
      ]
    end

    protected

    def size_to_thumbnail_filename_key(size: size, density_descriptor: nil)
      # gah we used two different vocabularies sorry
      filename_key = case size.to_s
        when "mini"
          "thumb_mini"
        when "standard"
          "thumb_standard"
        when "large"
          "thumb_hero"
        else
          raise ArgumentError.new("unrecognized size key: #{size.to_s}")
      end
      if density_descriptor
        filename_key += "_#{density_descriptor}"
      end

      filename_key
    end

  end
end
