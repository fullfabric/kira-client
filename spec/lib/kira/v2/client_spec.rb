describe Kira::V2::Client do
  describe "#initialize" do
    it "accepts a token kwarg" do
      client = Kira::V2::Client.new(token: "abc")
      expect(client).to be_a(Kira::V2::Client)
    end

    it "rejects a missing token" do
      expect { Kira::V2::Client.new(token: nil) }.to raise_error(ParamContractError)
    end

    it "rejects a non-string token" do
      expect { Kira::V2::Client.new(token: 123) }.to raise_error(ParamContractError)
    end

    it "accepts an optional base_url override" do
      client = Kira::V2::Client.new(token: "abc", base_url: "https://staging.example.com/api")
      expect(client).to be_a(Kira::V2::Client)
    end
  end

  describe "#interview" do
    let(:client) { Kira::V2::Client.new(token: "abc") }

    it "returns a per-interview accessor" do
      expect(client.interview("fqvjnY")).to be_a(Kira::V2::Interview)
    end

    it "rejects a non-string id" do
      expect { client.interview(123) }.to raise_error(ParamContractError)
    end
  end

  describe "#request" do
    let(:client) { Kira::V2::Client.new(token: KIRA_TOKEN) }
    let(:webhooks_url) { "#{Kira::V2::Client::BASE_URL}/interviews/#{KIRA_INTERVIEW_ID}/webhooks/" }

    context "on timeout" do
      it "lets the Faraday error propagate" do
        stub_request(:get, webhooks_url).to_timeout

        expect {
          client.request(:get, "/interviews/#{KIRA_INTERVIEW_ID}/webhooks/")
        }.to raise_error(Faraday::Error)
      end
    end

    context "with a custom base_url override" do
      let(:custom_base_url) { "https://staging.example.com/api" }
      let(:client) { Kira::V2::Client.new(token: KIRA_TOKEN, base_url: custom_base_url) }

      it "routes the request to the custom host" do
        stub = stub_request(:get, "#{custom_base_url}/interviews/abc/webhooks/")
                 .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

        client.request(:get, "/interviews/abc/webhooks/")

        expect(stub).to have_been_requested
      end
    end
  end
end
