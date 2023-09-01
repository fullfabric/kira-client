describe Kira::V2::Interview do

  BASE_URL = 'https://app.kiratalent.com/api'

  context 'interview' do

    let ( :conn ) { Faraday.new(BASE_URL) }
    let ( :interview_id ) { "fqvjnY" }
    let ( :token ) { "65a8412c301ed85974f03aa71f15ed107ce09786" }
    let ( :secret ) { "x49qwXDyAZDZTdizkLGg" }

    let ( :endpoint ) { "https://fullfabric.com/api/applics/kira/callback" }
    let ( :event_subscriptions ) { ["applicant.interview_completed"] }

    let!( :service ) { Kira::V2::Interview.new(interview_id, token, secret) }

    context 'creating a webhook' do

      context 'webhook exists' do

        before do
          url = "#{BASE_URL}/interviews/#{interview_id}/webhooks/"

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

        it 'returns true when webhook exists' do
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
          url = "#{BASE_URL}/interviews/#{interview_id}/webhooks/"

          res = conn.get do |req|
            req.url url
            req.headers["Authorization"] = " Token #{token}"
            req.headers["Accept"] = "application/vnd.kiratalent.v2+json"
            req.headers["Content-Type"] = "application/json"
          end

          webhooks = JSON.parse(res.body)

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

        it 'returns an hash with webhook details' do
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
