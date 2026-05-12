describe Kira::V2::Interview do
  let(:interview_id) { Faker::Alphanumeric.alphanumeric(number: 32) }
  let(:token) { Faker::Alphanumeric.alphanumeric(number: 40) }
  let(:secret) { Faker::Alphanumeric.alphanumeric(number: 20) }
  let(:webhooks_url) { "#{Kira::V2::Interview::BASE_URL}/interviews/#{interview_id}/webhooks/" }
  let(:endpoint) { "https://fullfabric.com/api/applics/kira/callback" }
  let(:event_subscriptions) { ["applicant.interview_completed"] }

  let(:service) { Kira::V2::Interview.new(interview_id, token, secret) }

  describe "#create" do
    context "when a webhook already subscribes the event" do
      before do
        stub_request(:get, webhooks_url).to_return(
          status: 200,
          body: [{
            "uid" => "abc123",
            "endpoint" => endpoint,
            "event_subscriptions" => ["applicant.interview_completed"]
          }].to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "returns true without POSTing a new webhook" do
        result = service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)

        expect(result).to eq(true)
        expect(WebMock).not_to have_requested(:post, webhooks_url)
      end
    end

    context "when no existing webhook subscribes the event" do
      let(:created_webhook) do
        {
          "uid" => "xyz789",
          "endpoint" => endpoint,
          "event_subscriptions" => event_subscriptions,
          "active" => true
        }
      end

      before do
        stub_request(:get, webhooks_url).to_return(
          status: 200,
          body: "[]",
          headers: { "Content-Type" => "application/json" }
        )

        stub_request(:post, webhooks_url).to_return(
          status: 201,
          body: created_webhook.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "creates the webhook and returns the response Hash" do
        result = service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)

        expect(result).to eq(created_webhook)
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

      it "sends the expected authentication and content headers" do
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
    end

    context "when the existing-webhook GET fails with 4xx" do
      it "raises Kira::Error" do
        stub_request(:get, webhooks_url).to_return(
          status: 401,
          body: { detail: "Invalid token" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

        expect {
          service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)
        }.to raise_error(Kira::Error)
      end
    end

    context "when the webhook POST fails with 4xx" do
      before do
        stub_request(:get, webhooks_url).to_return(status: 200, body: "[]")
        stub_request(:post, webhooks_url).to_return(
          status: 422,
          body: { errors: ["Endpoint is not reachable"] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "raises Kira::Error" do
        expect {
          service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)
        }.to raise_error(Kira::Error)
      end
    end

    context "when Kira returns a 5xx without a JSON body" do
      # XXX: SQ2-1050 will wrap this in a Kira::Error carrying the HTTP status.
      # Captured here so the regression test exists once the fix lands.
      it "leaks JSON::ParserError" do
        stub_request(:get, webhooks_url).to_return(
          status: 500,
          body: "<html><body>Internal Server Error</body></html>"
        )

        expect {
          service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)
        }.to raise_error(JSON::ParserError)
      end
    end

    context "when the request times out" do
      it "lets the Faraday error propagate" do
        stub_request(:get, webhooks_url).to_timeout

        expect {
          service.create(endpoint: endpoint, event_subscriptions: event_subscriptions)
        }.to raise_error(Faraday::Error)
      end
    end
  end
end
