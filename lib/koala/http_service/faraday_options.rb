module Koala
  module HTTPService
    class FaradayOptions
      VALID_OPTIONS = %i(
        request
        proxy
        ssl
        builder
        url
        parallel_manager
        params
        headers
        builder_class
      )

      def initialize options={}
        @options = options
      end

      def to_h
        Hash[
          options.select { |key,value|
            VALID_OPTIONS.include?(key) }
        ]
      end

      private

      attr_reader :options
    end
  end
end
