module Koala
  module HTTPService
    class PostRequest < Request
      def perform
        connection.post do |req|
          req.path =
          req.headers["Content-Type"] = "application/json"
          req.body = options.to_json
          req
        end
      end
    end
  end
end
