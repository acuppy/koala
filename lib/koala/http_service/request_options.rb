module Koala
  module HTTPService
    class RequestOptions
      def initialize params
        @params = params
      end

      def to_h
        { :params => (get? ? params.to_h : {}) }
      end

      def use_ssl?
        !!params.fetch(:access_token, false)
      end

      def ssl
        params[:ssl]          ||= {}
        params[:ssl][:verify] ||= true
        param.fetch :ssl
      end

      def api_version
        params.fetch :api_version, Koala.config.api_version
      end

      def method
        params.fetch :verb
      end

      def json?
        params[:format] == :json
      end

      private

      attr_reader :params

      def get?
        params[:method] == :get
      end
    end
  end
end
