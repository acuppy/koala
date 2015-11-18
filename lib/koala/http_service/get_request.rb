module Koala
  module HTTPService
    class GetRequest < Request
      def perform(connection, path, options)
        connection.get path, options
      end
    end
  end
end
