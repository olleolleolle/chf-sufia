class ChfRelatedUrlAttributeRenderer < CurationConcerns::Renderers::AttributeRenderer
  # Regexps for URLs that we dont' want to display.
  # * library catalog, we display fromm bib number elsewhere instead and don't,
  #   really need to enter as related url anymore.
  # * self-pointing work urls, we DO still enter here, but strip out and display
  #   elsewhere as 'related items'
  IGNORE_URLS_RE = Regexp.union(
    %r{\A\s*https?://othmerlib\.(chemheritage|sciencehistory)\.org/record=},
    CurationConcerns::GenericWorkShowPresenter::RELATED_WORK_PREFIX_RE
  )

  # override to filter out ones we want to ignore
  def values
    @filtered_values ||= begin
      original = super
      unless original.blank?
        original.reject do |value|
          value =~ IGNORE_URLS_RE
        end
      end
    end
  end


  private

    def li_value(value)
      link_to("<span class='glyphicon glyphicon-new-window'></span>&nbsp;".html_safe + abbreviated_value(value), value, target: "_blank")
    end

    def abbreviated_value(uri)
      uri =~ %r{https?\://([^/]+)}
      "#{$1}/..."
    end

end
