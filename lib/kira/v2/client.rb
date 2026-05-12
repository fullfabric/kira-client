module Kira
  module V2
    # Shared HTTP plumbing for the v2 API: Faraday connection, auth headers,
    # request dispatch, and response/error mapping. Mix in via `include Kira::V2::Client`
    # and set `@token` in the host class's initializer.
    module Client
      BASE_URL = 'https://app.kiratalent.com/api'.freeze

      private

      def conn
        @conn ||= Faraday.new(BASE_URL)
      end

      def auth_headers
        {
          "Authorization" => "Token #{@token}",
          "Accept"        => "application/vnd.kiratalent.v2+json",
          "Content-Type"  => "application/json"
        }
      end

      def request(method, path, body: nil)
        res = conn.send(method) do |req|
          req.url "#{BASE_URL}#{path}"
          req.headers.update(auth_headers)
          req.body = body.to_json if body
        end

        handle_response(res)
      end

      def handle_response(res)
        parsed = safe_json_parse(res.body)
        return parsed if res.success?

        raise _build_error(res, parsed)
      end

      def safe_json_parse(body)
        JSON.parse(body)
      rescue JSON::ParserError
        nil
      end

      def _build_error(res, parsed)
        klass = _applicant_already_exists?(res, parsed) ? Kira::ApplicantError::Exists : Kira::Error
        klass.new(status: res.status, body: res.body, parsed: parsed)
      end

      def _applicant_already_exists?(res, parsed)
        res.status == 409 &&
          parsed.is_a?(Hash) &&
          parsed["detail"].to_s.include?("already been registered")
      end
    end
  end
end
