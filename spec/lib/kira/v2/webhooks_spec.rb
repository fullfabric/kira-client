describe Kira::V2::Webhooks do
  let(:client)        { Kira::V2::Client.new(token: KIRA_TOKEN) }
  let(:interview_id)  { KIRA_INTERVIEW_ID }
  let(:webhooks)      { client.interview(interview_id).webhooks }
  let(:webhooks_url)  { "#{Kira::V2::Client::BASE_URL}/interviews/#{interview_id}/webhooks/" }
  let(:secret)        { KIRA_SECRET }
  let(:endpoint)      { "https://fullfabric.com/api/applics/kira/callback" }
  let(:event_subscriptions) { ["applicant.interview_completed"] }

  describe "#list" do
    context "when the interview has no webhooks",
            vcr: { cassette_name: "interview/create_new_webhook" } do
      # Cassette's first interaction is a real GET that returned an empty array.
      it "returns an empty array" do
        expect(webhooks.list).to eq([])
      end
    end

    context "when the interview has webhooks",
            vcr: { cassette_name: "interview/create_existing_webhook" } do
      it "returns the array of webhooks" do
        result = webhooks.list

        expect(result).to be_an(Array)
        expect(result.first).to include("uid", "endpoint", "event_subscriptions")
      end
    end

    context "when unauthorized",
            vcr: { cassette_name: "interview/get_unauthorized" } do
      it "raises Kira::Error with the HTTP 401 status" do
        expect { webhooks.list }.to raise_error(Kira::Error) { |e|
          expect(e.status).to eq(401)
        }
      end
    end

    # Cassette is hand-crafted (Kira won't return 5xx for us on demand) and
    # pinned with `record: :none` so it can't be accidentally re-recorded.
    context "when Kira returns a 5xx without a JSON body",
            vcr: { cassette_name: "interview/server_error_html", record: :none } do
      it "raises Kira::Error carrying the HTTP status and raw body" do
        expect { webhooks.list }.to raise_error(Kira::Error) { |e|
          expect(e.status).to eq(500)
          expect(e.body).to include("Internal Server Error")
          expect(e.parsed).to be_nil
        }
      end
    end

    context "when the request times out" do
      it "lets the Faraday error propagate" do
        stub_request(:get, webhooks_url).to_timeout
        expect { webhooks.list }.to raise_error(Faraday::Error)
      end
    end
  end

  describe "#create" do
    context "on success",
            vcr: { cassette_name: "interview/create_new_webhook" } do
      # Cassette's second interaction is the POST recording.
      it "returns the created webhook" do
        webhook = webhooks.create(
          endpoint: endpoint,
          event_subscriptions: event_subscriptions,
          secret: secret
        )

        expect(webhook).to be_a(Hash)
        expect(webhook["endpoint"]).to eq(endpoint)
        expect(webhook["event_subscriptions"]).to eq(event_subscriptions)
        expect(webhook["uid"]).not_to be_empty
      end

      it "POSTs endpoint, events, active flag, and secret" do
        webhooks.create(
          endpoint: endpoint,
          event_subscriptions: event_subscriptions,
          secret: secret
        )

        expect(WebMock).to have_requested(:post, webhooks_url).with { |req|
          body = JSON.parse(req.body)
          body["endpoint"] == endpoint &&
            body["event_subscriptions"] == event_subscriptions &&
            body["active"] == true &&
            body["secret"] == secret
        }
      end
    end
  end

  describe "#delete" do
    # Hand-crafted (we don't need a real recording for a 204).
    context "on success",
            vcr: { cassette_name: "interview/delete_webhook", record: :none } do
      it "returns nil on 204 No Content" do
        result = webhooks.delete("fixture-uid")
        expect(result).to be_nil
      end

      it "DELETEs the webhook by uid" do
        webhooks.delete("fixture-uid")
        expect(WebMock).to have_requested(:delete, "#{webhooks_url}fixture-uid/")
      end
    end
  end
end
