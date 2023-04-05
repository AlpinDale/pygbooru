# frozen_string_literal: true

class Source::Extractor
  class Furaffinity < Source::Extractor
    def self.enabled?
      # https://www.furaffinity.net/controls/settings/
      # For this strategy to work properly, in the above settings "Enable Adult Artwork" must be set to "General, Mature, Adult".
      Danbooru.config.furaffinity_cookie_a.present? && Danbooru.config.furaffinity_cookie_b.present?
    end

    def match?
      Source::URL::Furaffinity === parsed_url
    end

    def image_urls
      if parsed_url.image_url?
        [parsed_url.to_s]
      else
        download_button = html_response&.css(".submission-content .auto_link .button").to_a.find { |el| el.text == "Download" }
        partial_image = download_button&.[]("href")
        return [] unless partial_image.present?
        [Addressable::URI.join("https://d.furaffinity.net", partial_image).to_s].compact
      end
    end

    def page_url
      parsed_url.page_url || parsed_referer&.page_url
    end

    def tags
      tags = html_response&.css(".tags").to_a.map!(&:text).compact.uniq
      tags.map {|tag| [tag, "https://www.furaffinity.net/search/@keywords #{tag}"] }
    end

    def artist_name
      html_response&.at(".submission-id-sub-container a")&.text || parsed_url.username || parsed_referer&.username
    end

    def profile_url
      parsed_url.profile_url || parsed_referer&.profile_url || profile_url_from_page
    end

    def profile_url_from_page
      slug = html_response&.at(".submission-id-avatar a")&.[](:href)
      return unless slug.present?
      Source::URL.parse(URI.join("https://www.furaffinity.net/", slug)).profile_url
    end

    def artist_commentary_title
      html_response&.at(".submission-title")&.text&.strip
    end

    def artist_commentary_desc
      html_response&.at(".submission-content .section-body")&.to_html
    end

    def dtext_artist_commentary_desc
      DText.from_html(artist_commentary_desc)&.strip
    end

    def html_response
      return nil unless page_url.present?
      response = http.cache(1.minute).get(page_url)

      return nil unless response.status == 200
      response.parse
    end

    def http
      super.cookies(a: Danbooru.config.furaffinity_cookie_a, b: Danbooru.config.furaffinity_cookie_b, sfw: 0)
    end
  end
end
