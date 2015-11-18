module Koala
  module HTTPService
    require 'delegate'

    class RequestParams < SimpleDelegator
      def initialize params
        super params.inject({}, &normalizer)
      end

      def merge *addl_params
        addl_params.each { |p| super p || {} }
      end

      def merge! *addl_params
        addl_params.each { |p| super p || {} }
      end

      private

      def normalizer
        -> (memo, hash) do
          key, value = hash
          memo[key] = normal_value(value)
          memo
        end
      end

      def normal_value value
        value.responds_to?(:to_upload_io) ? value.to_upload_io : value
      end
    end
  end
end
