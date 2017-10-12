# Generated by curation_concerns:models:install
class FileSet < ActiveFedora::Base
  include ::CurationConcerns::FileSetBehavior
  include Sufia::FileSetBehavior

  self.indexer = CHF::FileSetIndexer

  def create_derivatives(filename)
    # TODO delete this override all of this.

    # use layer 0 to create our derivatives
    if self.class.image_mime_types.include? mime_type
      begin
        # create a preview derivative for image assets
        Hydra::Derivatives::ImageDerivatives.create(filename,
                                                    outputs: [{ label: :preview, format: 'jpg', size: '1000x750>', url: derivative_url('jpeg'), layer: 0 }])
        Hydra::Derivatives::ImageDerivatives.create(filename,
                                                    outputs: [{ label: :thumbnail, format: 'jpg', size: '200x150>', url: derivative_url('thumbnail'), layer: 0 }])
      rescue => e
        Rails.logger.error "Derivatives creation failed for #{id}: #{e}"
      end
    else
      # any other mime_type uses default behavior
      super
    end
  end

end
