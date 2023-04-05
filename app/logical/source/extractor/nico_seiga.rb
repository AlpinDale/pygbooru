# frozen_string_literal: true

# @see Source::URL::NicoSeiga
module Source
  class Extractor
    class NicoSeiga < Source::Extractor
      def self.enabled?
        Danbooru.config.nico_seiga_user_session.present?
      end

      def match?
        Source::URL::NicoSeiga === parsed_url
      end

      def image_urls
        if image_id.present?
          [image_url_for("https://seiga.nicovideo.jp/image/source/#{image_id}") || url]
        elsif illust_id.present?
          [image_url_for("https://seiga.nicovideo.jp/image/source/#{illust_id}") || url]
        elsif manga_id.present?
          api_client.manga_api_response.pluck("meta").pluck("source_url").map do |url|
            image_id = Source::URL.parse(url).image_id
            image_url_for("https://seiga.nicovideo.jp/image/source/#{image_id}") || url
          end
        else
          [image_url_for(url) || url]
        end
      end

      def image_url_for(url)
        return nil if api_client.blank?

        resp = api_client.head(url)
        if resp.uri.to_s =~ %r{https?://.+/(\w+/\d+/\d+)\z}i
          "https://lohas.nicoseiga.jp/priv/#{$1}"
        else
          nil
        end
      end

      def page_url
        parsed_referer&.page_url || parsed_url.page_url
      end

      def profile_url
        "https://seiga.nicovideo.jp/user/illust/#{artist_id}" if artist_id.present?
      end

      def artist_name
        return if api_client.blank?
        api_client.user_name
      end

      def artist_commentary_title
        return if api_client.blank?
        api_client.title
      end

      def artist_commentary_desc
        return if api_client.blank?
        api_client.description
      end

      def dtext_artist_commentary_desc
        DText.from_html(artist_commentary_desc) do |element|
          if element.name == "font" && element["color"] == "white"
            element.content = "[spoiler]#{element.content}[/spoiler]"
          end
        end.gsub(/[^\w]im(\d+)/, ' seiga #\1 ').chomp
      end

      def tag_name
        "nicoseiga_#{artist_id}" if artist_id.present?
      end

      def other_names
        [artist_name].compact
      end

      def tags
        return [] if api_client.blank?

        api_client.tags.map do |name|
          [name, "https://seiga.nicovideo.jp/#{"manga/" if manga_id}tag/#{Danbooru::URL.escape(name)}"]
        end
      end

      def image_id
        parsed_url.image_id || parsed_referer&.image_id
      end

      def illust_id
        parsed_url.illust_id || parsed_referer&.illust_id
      end

      def manga_id
        parsed_url.manga_id || parsed_referer&.manga_id
      end

      def artist_id
        api_client&.user_id
      end

      def http
        if parsed_url.oekaki_id.present?
          super.with_legacy_ssl
        else
          super
        end
      end

      def api_client
        if illust_id.present?
          NicoSeigaApiClient.new(work_id: illust_id, type: "illust", http: http)
        elsif manga_id.present?
          NicoSeigaApiClient.new(work_id: manga_id, type: "manga", http: http)
        elsif image_id.present?
          # We default to illust to attempt getting the api anyway
          NicoSeigaApiClient.new(work_id: image_id, type: "illust", http: http)
        end
      end
      memoize :api_client
    end
  end
end
