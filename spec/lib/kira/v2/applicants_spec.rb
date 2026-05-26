describe Kira::V2::Applicants do
  let(:client)        { Kira::V2::Client.new(token: KIRA_TOKEN) }
  let(:interview_id)  { KIRA_INTERVIEW_ID }
  let(:applicants)    { client.interview(interview_id).applicants }
  let(:applicant_url) { "#{Kira::V2::Client::BASE_URL}/interviews/#{interview_id}/applicants/" }

  describe "#create" do
    context "on success", vcr: { cassette_name: "applicant/create_success" } do
      it "returns the parsed applicant with the external_id echoed back" do
        applicant = applicants.create(
          first_name: "Peter",
          last_name: "Pan",
          email: "peter.pan+fixture-001@example.com",
          external_id: "ext-fixture-001"
        )

        expect(applicant["external_id"]).to eq("ext-fixture-001")
        expect(applicant.keys).to include("email", "external_id", "check_in_page_url")
      end
    end

    context "on success (no external_id)", vcr: { cassette_name: "applicant/create_success_no_external_id" } do
      it "returns an applicant with a check-in URL" do
        applicant = applicants.create(
          first_name: "Peter",
          last_name: "Pan",
          email: "peter.pan+fixture-002@example.com"
        )

        expect(applicant["check_in_page_url"]).to match(URI::DEFAULT_PARSER.make_regexp(["https"]))
      end

      it "sends Authorization, Accept, and Content-Type headers" do
        applicants.create(first_name: "Peter", last_name: "Pan", email: "peter.pan+fixture-002@example.com")

        expect(WebMock).to have_requested(:post, applicant_url).with(
          headers: {
            "Authorization" => "Token #{KIRA_TOKEN}",
            "Accept" => "application/vnd.kiratalent.v2+json",
            "Content-Type" => "application/json"
          }
        )
      end

      it "POSTs the applicant params as JSON" do
        applicants.create(first_name: "Peter", last_name: "Pan", email: "peter.pan+fixture-002@example.com")

        expect(WebMock).to have_requested(:post, applicant_url).with { |req|
          body = JSON.parse(req.body)
          body == { "first_name" => "Peter", "last_name" => "Pan", "email" => "peter.pan+fixture-002@example.com" }
        }
      end
    end

    context "when the applicant already exists", vcr: { cassette_name: "applicant/create_duplicate" } do
      let(:params) do
        {
          first_name: "Peter",
          last_name: "Pan",
          email: "peter.pan+fixture-duplicate@example.com"
        }
      end

      it "raises Kira::ApplicantError::Exists on the second create" do
        applicants.create(**params)

        expect { applicants.create(**params) }.to raise_error(Kira::ApplicantError::Exists) { |e|
          expect(e.status).to eq(409)
          expect(e.parsed["detail"]).to include("already been registered")
        }
      end
    end

    # Kira's API has been observed returning the duplicate-registration error
    # as 400 with a bare JSON string body (instead of 409 + Hash). Pinned to
    # record: :none so the cassette stays stable.
    context "when Kira returns the duplicate error as 400 + bare string",
            vcr: { cassette_name: "applicant/create_duplicate_400_string", record: :none } do
      it "still raises Kira::ApplicantError::Exists" do
        expect {
          applicants.create(first_name: "Peter", last_name: "Pan", email: "peter@example.com")
        }.to raise_error(Kira::ApplicantError::Exists) { |e|
          expect(e.status).to eq(400)
          expect(e.parsed).to be_a(String)
          expect(e.parsed).to include("already been registered")
        }
      end
    end

    context "when the email is invalid", vcr: { cassette_name: "applicant/create_invalid_email" } do
      it "raises Kira::Error with the HTTP status and parsed body" do
        expect {
          applicants.create(first_name: "Peter", last_name: "Pan", email: "not-an-email")
        }.to raise_error(Kira::Error) { |e|
          expect(e.status).to eq(400)
          expect(e.parsed).to be_a(Hash)
        }
      end
    end

    # Cassette is hand-crafted (Kira won't return 5xx for us on demand) and
    # pinned with `record: :none` so it can't be accidentally re-recorded.
    context "when Kira returns a 5xx without a JSON body",
            vcr: { cassette_name: "applicant/create_server_error_html", record: :none } do
      it "raises Kira::Error carrying the HTTP status and raw body" do
        expect {
          applicants.create(first_name: "Peter", last_name: "Pan", email: "peter@example.com")
        }.to raise_error(Kira::Error) { |e|
          expect(e.status).to eq(500)
          expect(e.body).to include("Internal Server Error")
          expect(e.parsed).to be_nil
        }
      end
    end
  end

  describe "#list" do
    context "with an email filter that matches one applicant",
            vcr: { cassette_name: "applicant/list_by_email_match", record: :none } do
      it "returns a single-element array carrying check_in_page_url" do
        results = applicants.list(email: "peter.pan+fixture-001@example.com")

        expect(results.size).to eq(1)
        expect(results.first["email"]).to eq("peter.pan+fixture-001@example.com")
        expect(results.first["check_in_page_url"]).to start_with("https://app.kiratalent.com/applicant/")
      end

      it "sends the email as a URL-encoded query parameter" do
        applicants.list(email: "peter.pan+fixture-001@example.com")

        # Faraday leaves `@` unescaped in the query (it's a safe character there),
        # but `+` must be escaped or Kira parses it as a space.
        expect(WebMock).to have_requested(
          :get,
          "#{applicant_url}?email=peter.pan%2Bfixture-001@example.com"
        )
      end
    end

    context "with an email filter that matches nothing",
            vcr: { cassette_name: "applicant/list_by_email_empty", record: :none } do
      it "returns an empty array" do
        expect(applicants.list(email: "nobody@example.com")).to eq([])
      end
    end

    context "without an email filter",
            vcr: { cassette_name: "applicant/list_all", record: :none } do
      it "GETs the unfiltered applicants index" do
        applicants.list

        expect(WebMock).to have_requested(:get, applicant_url)
      end
    end
  end

  describe "#get" do
    context "for an existing uid",
            vcr: { cassette_name: "applicant/get_success", record: :none } do
      it "returns the applicant hash with check_in_page_url" do
        applicant = applicants.get("zIUiHR")

        expect(applicant["uid"]).to eq("zIUiHR")
        expect(applicant["email"]).to eq("peter.pan+fixture-001@example.com")
        expect(applicant["check_in_page_url"]).to start_with("https://app.kiratalent.com/applicant/")
      end

      it "GETs the per-applicant URL" do
        applicants.get("zIUiHR")

        expect(WebMock).to have_requested(:get, "#{applicant_url}zIUiHR/")
      end
    end

    context "for an unknown uid",
            vcr: { cassette_name: "applicant/get_not_found", record: :none } do
      it "raises Kira::Error with status 404" do
        expect { applicants.get("missing") }.to raise_error(Kira::Error) { |e|
          expect(e.status).to eq(404)
        }
      end
    end
  end
end
