describe Kira::V2::Applicant do
  let(:interview_id) { KIRA_INTERVIEW_ID }
  let(:token)        { KIRA_TOKEN }
  let(:applicant_url) { "#{Kira::V2::Applicant::BASE_URL}/interviews/#{interview_id}/applicants/" }
  let(:service)      { Kira::V2::Applicant.new(interview_id, token) }

  describe "#create" do
    context "on success", vcr: { cassette_name: "applicant/create_success" } do
      let(:external_id) { "ext-fixture-001" }
      let(:applicant_params) do
        {
          first_name: "Peter",
          last_name: "Pan",
          email: "peter.pan+fixture-001@example.com",
          external_id: external_id
        }
      end

      it "returns the parsed applicant with the external_id echoed back" do
        applicant = service.create(applicant_params)

        expect(applicant["external_id"]).to eq(external_id)
        expect(applicant.keys).to include("email", "external_id", "check_in_page_url")
      end
    end

    context "on success (no external_id)", vcr: { cassette_name: "applicant/create_success_no_external_id" } do
      let(:applicant_params) do
        {
          first_name: "Peter",
          last_name: "Pan",
          email: "peter.pan+fixture-002@example.com"
        }
      end

      it "returns an applicant with a check-in URL" do
        applicant = service.create(applicant_params)

        expect(applicant["check_in_page_url"]).to match(URI::DEFAULT_PARSER.make_regexp(["https"]))
      end

      it "sends Authorization, Accept, and Content-Type headers" do
        service.create(applicant_params)

        # The source sets `" Token #{@token}"` with a leading space, but Faraday
        # normalises header values on the wire, so the leading space never goes out.
        expect(WebMock).to have_requested(:post, applicant_url).with(
          headers: {
            "Authorization" => "Token #{token}",
            "Accept" => "application/vnd.kiratalent.v2+json",
            "Content-Type" => "application/json"
          }
        )
      end

      it "POSTs the applicant params as JSON" do
        service.create(applicant_params)

        expect(WebMock).to have_requested(:post, applicant_url).with { |req|
          JSON.parse(req.body) == JSON.parse(applicant_params.to_json)
        }
      end
    end

    context "when the applicant already exists", vcr: { cassette_name: "applicant/create_duplicate" } do
      let(:applicant_params) do
        {
          first_name: "Peter",
          last_name: "Pan",
          email: "peter.pan+fixture-duplicate@example.com"
        }
      end

      it "raises Kira::Error when posting the same applicant twice" do
        service.create(applicant_params)
        expect { service.create(applicant_params) }.to raise_error(Kira::Error)
      end
    end

    context "when the email is invalid", vcr: { cassette_name: "applicant/create_invalid_email" } do
      let(:applicant_params) do
        {
          first_name: "Peter",
          last_name: "Pan",
          email: "not-an-email"
        }
      end

      it "raises Kira::Error" do
        expect { service.create(applicant_params) }.to raise_error(Kira::Error)
      end
    end

    # XXX: SQ2-1050 will wrap this in a Kira::Error carrying the HTTP status.
    # Cassette is hand-crafted (Kira won't return 5xx for us on demand) and
    # pinned with `record: :none` so it can't be accidentally re-recorded.
    context "when Kira returns a 5xx without a JSON body",
            vcr: { cassette_name: "applicant/create_server_error_html", record: :none } do
      let(:applicant_params) do
        { first_name: "Peter", last_name: "Pan", email: "peter@example.com" }
      end

      it "leaks JSON::ParserError" do
        expect { service.create(applicant_params) }.to raise_error(JSON::ParserError)
      end
    end

    context "when the request times out" do
      let(:applicant_params) do
        { first_name: "Peter", last_name: "Pan", email: "peter@example.com" }
      end

      # Timeouts can't be represented in a VCR cassette; bare WebMock stub instead.
      it "lets the Faraday error propagate" do
        stub_request(:post, applicant_url).to_timeout

        expect { service.create(applicant_params) }.to raise_error(Faraday::Error)
      end
    end
  end
end
