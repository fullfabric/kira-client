class Kira::V2::Interview
  include Contracts
  include Kira::V2::Client

  Contract String, String, String, KeywordArgs[base_url: Optional[String]] => Any
  def initialize(interview_id, token, secret, base_url: nil)
    @interview_id, @token, @secret, @base_url = interview_id, token, secret, base_url
  end

  Contract KeywordArgs[
    endpoint: String,
    event_subscriptions: ArrayOf[String],
    active: Optional[Bool]
  ] => Or[Hash, Bool]
  def create(endpoint:, event_subscriptions:, active: true)
    path = "/interviews/#{@interview_id}/webhooks/"

    existing = request(:get, path)
    return true if existing.any? { |webhook| webhook['event_subscriptions'].include?('applicant.interview_completed') }

    request(:post, path, body: {
      endpoint: endpoint,
      event_subscriptions: event_subscriptions,
      active: active,
      secret: @secret
    })
  end
end
