describe Kira::V2::Interview do
  let(:interview_id) { KIRA_INTERVIEW_ID }
  let(:token)        { KIRA_TOKEN }
  let(:secret)       { KIRA_SECRET }
  let(:webhooks_url) { "#{Kira::V2::Interview::BASE_URL}/interviews/#{interview_id}/webhooks/" }
  let(:endpoint)     { "https://fullfabric.com/api/applics/kira/callback" }
  let(:event_subscriptions) { ["applicant.interview_completed"] }

  let(:service) { Kira::V2::Interview.new(interview_id, token, secret) }

  describe "#create" do
    context "when no existing webhook subscribes the event",
            vcr: { cassette_name: "interview/create_new_webhook" } do

      it "creates the webhook and returns the response Hash" do
        webhook = service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)

        expect(webhook).to be_a(Hash)
        expect(webhook['endpoint']).to eq(endpoint)
        expect(webhook['event_subscriptions']).to eq(event_subscriptions)
        expect(webhook['uid']).not_to be_empty
      end

      it "sends Authorization, Accept, and Content-Type headers" do
        service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)

        # The source sets `" Token #{@token}"` with a leading space, but Faraday
        # normalises header values on the wire, so the leading space never goes out.
        expect(WebMock).to have_requested(:post, webhooks_url).with(
          headers: {
            "Authorization" => "Token #{token}",
            "Accept" => "application/vnd.kiratalent.v2+json",
            "Content-Type" => "application/json"
          }
        )
      end

      it "POSTs endpoint, events, active flag, and secret" do
        service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)

        expect(WebMock).to have_requested(:post, webhooks_url).with { |req|
          body = JSON.parse(req.body)
          body["endpoint"] == endpoint &&
            body["event_subscriptions"] == event_subscriptions &&
            body["active"] == true &&
            body["secret"] == secret
        }
      end
    end

    context "when a webhook already subscribes the event",
            vcr: { cassette_name: "interview/create_existing_webhook" } do

      it "returns true without POSTing a new webhook" do
        result = service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)

        expect(result).to eq(true)
        expect(WebMock).not_to have_requested(:post, webhooks_url)
      end
    end

    context "when the existing-webhook GET is unauthorized",
            vcr: { cassette_name: "interview/get_unauthorized" } do
      let(:token) { "definitely-not-a-real-token" }

      it "raises Kira::Error" do
        expect {
          service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)
        }.to raise_error(Kira::Error)
      end
    end

    # XXX: SQ2-1050 will wrap this in a Kira::Error carrying the HTTP status.
    # Cassette is hand-crafted (Kira won't return 5xx for us on demand) and
    # pinned with `record: :none` so it can't be accidentally re-recorded.
    context "when Kira returns a 5xx without a JSON body",
            vcr: { cassette_name: "interview/server_error_html", record: :none } do
      it "leaks JSON::ParserError" do
        expect {
          service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)
        }.to raise_error(JSON::ParserError)
      end
    end

    context "when the request times out" do
      # Timeouts can't be represented in a VCR cassette; bare WebMock stub instead.
      it "lets the Faraday error propagate" do
        stub_request(:get, webhooks_url).to_timeout

        expect {
          service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)
        }.to raise_error(Faraday::Error)
      end
    end
  end
end
