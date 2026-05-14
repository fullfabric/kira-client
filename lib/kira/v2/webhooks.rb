class Kira::V2::Webhooks
  include Contracts

  def initialize(client, interview_id)
    @client, @interview_id = client, interview_id
  end

  Contract None => ArrayOf[Hash]
  def list
    @client.request(:get, "/interviews/#{@interview_id}/webhooks/")
  end

  Contract KeywordArgs[
    endpoint: String,
    event_subscriptions: ArrayOf[String],
    secret: String,
    active: Optional[Bool]
  ] => Hash
  def create(endpoint:, event_subscriptions:, secret:, active: true)
    @client.request(:post, "/interviews/#{@interview_id}/webhooks/", body: {
      endpoint: endpoint,
      event_subscriptions: event_subscriptions,
      active: active,
      secret: secret
    })
  end

  Contract String => Any
  def delete(uid)
    @client.request(:delete, "/interviews/#{@interview_id}/webhooks/#{uid}/")
  end
end
