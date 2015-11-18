module Koala
  module HTTPService
    class Response
      # Creates a new Response object, which standardizes the response received by Facebook for use within Koala.
      def initialize(*response)
        case response.length
        when 1
          @response = response.first
        when 3 # deprecated / legacy support
          @status   = response[0]
          @body     = response[1]
          @headers  = response[2]
        end
      end

      def status
        @status  ||= response.status.to_i
      end

      def body
        @body    ||= response.body
      end

      def headers
        @headers ||= response.headers
      end

      private

      attr_reader :response
    end
  end

  # @private
  # legacy support for when Response lived directly under Koala
  Response = HTTPService::Response
end
