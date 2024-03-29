class Kira::V2::Interview
  include Contracts

  BASE_URL = 'https://app.kiratalent.com/api'

  Contract String, String, String => Object
  def initialize(interview_id, token, secret)
    @interview_id, @token, @secret = interview_id, token, secret
  end

  Contract Hash => Or[Hash,Bool]
  def create(endpoint:, event_subscriptions:, active: true)
    url = "#{BASE_URL}/interviews/#{@interview_id}/webhooks/"

    # check first if a webhook for this interview already exists
    res = conn.get do |req|
      req.url url
      req.headers["Authorization"] = " Token #{@token}"
      req.headers["Accept"] = "application/vnd.kiratalent.v2+json"
      req.headers["Content-Type"] = "application/json"
    end

    response = JSON.parse(res.body)
    handle_error(response) unless res.success?

    # return if a webhook already exists
    return true if response.any? { |webhook| webhook['event_subscriptions'].include?('applicant.interview_completed') }

    # create a webhook otherwise
    request_body = {
      "endpoint": endpoint,
      "event_subscriptions": event_subscriptions,
      "active": active,
      "secret": @secret
    }

    res = conn.post do |req|
      req.url url
      req.headers["Authorization"] = " Token #{@token}"
      req.headers["Accept"] = "application/vnd.kiratalent.v2+json"
      req.headers["Content-Type"] = "application/json"
      req.body = request_body.to_json
    end

    response = JSON.parse(res.body)
    res.success? ? response : handle_error(response)
  end

  private

    def conn
      @conn ||= Faraday.new(BASE_URL)
    end

    def handle_error(response)
      raise Kira::Error.new(response)
    end

end
