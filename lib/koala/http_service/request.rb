module Koala
  module HTTPService
    require 'faraday_options'

    class Request
      DEFAULT_MIDDLEWARE = Proc.new do |builder|
        builder.use Koala::HTTPService::MultipartRequest
        builder.request :url_encoded
        builder.adapter Faraday.default_adapter
      end

      def initialize path, options
        @path    = path
        @options = options
      end

      def root_url
        root_url = default_root_url
        root_url.gsub! Koala.config.host_path_matcher, Koala.config.video_replace if options[:video]
        root_url.gsub! Koala.config.host_path_matcher, Koala.config.beta_replace if options[:beta]
        "#{protocol}://#{root_url}"
      end

      private

      attr_reader :path, :options

      def protocol
        options.use_ssl? ? "https" : "http"
      end

      def default_root_url
        options[:rest_api] ? Koala.config.rest_server : Koala.config.graph_server
      end

      def path
        unless HTTPService.path_contains_api_version? @path
          File.join options.api_version, @path
        else
          @path
        end
      end

      def connection
        @connection ||=
          Faraday.new server, faraday_options, &middleware
      end

      def faraday_options
        FaradayOptions.new(options).to_h
      end

      def middleware
        HTTPService.faraday_middleware || DEFAULT_MIDDLEWARE
      end
    end
  end
end
