require 'net/http'

# Monkey patch Database::Client to stream response directly into another stream
module Databasedotcom
  class Client

    # This method performs a streaming download. If download is not successful, throws an exception
    # without
    def http_streaming_get(path, stream)
      connection = Net::HTTP.new(URI.parse(self.instance_url).host, 443)
      connection.use_ssl = true
      encoded_path = URI.escape(path)
      log_request(encoded_path)

      req = Net::HTTP::Get.new(encoded_path, {"Authorization" => "OAuth #{self.oauth_token}"})
      connection.request(req) do |response|
        raise SalesForceError.new(response) unless response.is_a?(Net::HTTPSuccess)
        response.read_body do |chunk|
          stream.write chunk
        end
      end

      nil
    end
  end
end