describe Kira::V2::Applicant do
  let(:interview_id) { Faker::Alphanumeric.alphanumeric(number: 32) }
  let(:token) { Faker::Alphanumeric.alphanumeric(number: 40) }
  let(:applicant_url) { "#{Kira::V2::Applicant::BASE_URL}/interviews/#{interview_id}/applicants/" }
  let(:service) { Kira::V2::Applicant.new(interview_id, token) }

  let(:applicant_params) do
    {
      first_name: "Peter",
      last_name: "Pan",
      email: Faker::Internet.email
    }
  end

  describe "#create" do
    context "on success" do
      let(:external_id) { Faker::Internet.uuid }
      let(:response_body) do
        {
          email: applicant_params[:email],
          external_id: external_id,
          check_in_page_url: "https://app.kiratalent.com/applicant/#{Faker::Alphanumeric.alphanumeric(number: 24)}/check-in"
        }.to_json
      end

      before do
        stub_request(:post, applicant_url).to_return(
          status: 201,
          body: response_body,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "returns the parsed applicant" do
        applicant = service.create(applicant_params.merge(external_id: external_id))

        expect(applicant["external_id"]).to eq(external_id)
        expect(applicant.keys).to include("email", "external_id", "check_in_page_url")
      end

      it "returns a check-in URL" do
        applicant = service.create(applicant_params)
        expect(applicant["check_in_page_url"]).to match(URI::DEFAULT_PARSER.make_regexp(["https"]))
      end

      it "sends the expected authentication and content headers" do
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

    context "when Kira rejects the request with a 4xx" do
      it "raises Kira::Error on duplicate applicant" do
        stub_request(:post, applicant_url).to_return(
          status: 400,
          body: { errors: ["Applicant already exists"] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

        expect { service.create(applicant_params) }.to raise_error(Kira::Error)
      end

      it "raises Kira::Error on validation failure" do
        stub_request(:post, applicant_url).to_return(
          status: 422,
          body: { email: ["is invalid"] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

        expect { service.create(applicant_params) }.to raise_error(Kira::Error)
      end
    end

    context "when Kira returns a 5xx without a JSON body" do
      # XXX: SQ2-1050 will wrap this in a Kira::Error carrying the HTTP status.
      # Captured here so the regression test exists once the fix lands.
      it "leaks JSON::ParserError" do
        stub_request(:post, applicant_url).to_return(
          status: 500,
          body: "<html><body>Internal Server Error</body></html>"
        )

        expect { service.create(applicant_params) }.to raise_error(JSON::ParserError)
      end
    end

    context "when the request times out" do
      it "lets the Faraday error propagate" do
        stub_request(:post, applicant_url).to_timeout

        expect { service.create(applicant_params) }.to raise_error(Faraday::Error)
      end
    end
  end
end
