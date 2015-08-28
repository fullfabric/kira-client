module KiraClient
  class Auth

    BASE_URL = 'https://app.kiratalent.com/api'

    def initialize credentials
      @key, @secret = credentials[:key], credentials[:secret]
    end

    def access_token

      data = {
        client_key: @key,
        client_secret: @secret,
        grant_type: 'client_credentials'
      }

      response = conn.post("#{BASE_URL}/oauth/access_token", data)

      JSON.parse(response.body)['access_token']

    end

    private

      def conn
        @conn ||= Faraday.new(BASE_URL)
      end

  end
end
