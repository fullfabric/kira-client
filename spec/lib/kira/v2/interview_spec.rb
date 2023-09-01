describe Kira::V2::Interview do

  BASE_URL = 'https://app.kiratalent.com/api'
  INTERVIEW_ID = 'fqvjnY'

  context 'interview' do

    let ( :conn ) { Faraday.new(BASE_URL) }
    let ( :url ) { "#{BASE_URL}/interviews/#{INTERVIEW_ID}/webhooks/" }
    let ( :token ) { "65a8412c301ed85974f03aa71f15ed107ce09786" }
    let ( :secret ) { "x49qwXDyAZDZTdizkLGg" }
    let ( :endpoint ) { "https://fullfabric.com/api/applics/kira/callback" }
    let ( :event_subscriptions ) { ["applicant.interview_completed"] }

    let!( :service ) { Kira::V2::Interview.new(INTERVIEW_ID, token, secret) }

    after(:each) do
      _delete_existing_interview_webhooks!
    end

    context 'creating a webhook' do

      context 'webhook exists' do

        before do
          _create_interview_webhook!
        end

        it 'returns true when webhook exists' do
          expect(_get_existing_interview_webhooks).not_to be_empty
          expect(
            service.create(
              endpoint: endpoint,
              event_subscriptions: event_subscriptions
            )
          ).to eq(true)
        end

      end

      context 'webhook does not exist' do

        before do
          _delete_existing_interview_webhooks!
        end

        it 'creates a new webhook and returns webhook details' do
          expect(_get_existing_interview_webhooks).to be_empty

          webhook = service.create(
            endpoint: endpoint,
            event_subscriptions: event_subscriptions
          )

          expect(webhook).to be_a(Hash)
          expect(webhook['uid']).not_to be_empty
          expect(webhook['endpoint']).to eq(endpoint)
          expect(webhook['event_subscriptions']).to eq(event_subscriptions)
        end

      end

    end

  end

end

private

  def _create_interview_webhook!
    request_body = {
      "endpoint": endpoint,
      "active": true,
      "event_subscriptions": event_subscriptions,
      "secret": secret
    }

    conn.post do |req|
      req.url url
      req.headers["Authorization"] = " Token #{token}"
      req.headers["Accept"] = "application/vnd.kiratalent.v2+json"
      req.headers["Content-Type"] = "application/json"
      req.body = request_body.to_json
    end
  end

  def _get_existing_interview_webhooks
    res = conn.get do |req|
      req.url url
      req.headers["Authorization"] = " Token #{token}"
      req.headers["Accept"] = "application/vnd.kiratalent.v2+json"
      req.headers["Content-Type"] = "application/json"
    end

    webhooks = JSON.parse(res.body)
    webhooks
  end

  def _delete_existing_interview_webhooks!
    webhooks = _get_existing_interview_webhooks

    webhooks.each do |webhook|
      webhook_url = url + "#{webhook['uid']}/"
      conn.delete do |req|
        req.url webhook_url
        req.headers["Authorization"] = " Token #{token}"
        req.headers["Accept"] = "application/vnd.kiratalent.v2+json"
        req.headers["Content-Type"] = "application/json"
      end
    end
  end
