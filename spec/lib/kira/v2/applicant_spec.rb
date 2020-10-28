describe Kira::V2::Applicant do

  context 'interview' do

    let ( :interview_id ) { "fqvjnY" }
    let ( :token ) { "65a8412c301ed85974f03aa71f15ed107ce09786" }

    let!( :service ) { Kira::V2::Applicant.new(interview_id, token) }

    context 'creating an applicant' do

      context 'passing an external id' do

        let!(:external_id) { Faker::Internet.uuid }

        it 'returns external id' do
          params = {
            first_name: 'Peter',
            last_name: 'Pan',
            email: "peter.pan#{Faker::Number.number(digits: 8)}@gmail.com",
            external_id: external_id
          }

          applicant = service.create(params)
          expect(applicant['external_id']).to eq(external_id)
        end

      end

      it 'returns an applicant' do

        applicant = {
          first_name: "Peter",
          last_name: "Pan",
          email: "peter.pan#{Faker::Number.number(digits: 8)}@gmail.com"
        }

        applicant = service.create(applicant)
        expect(applicant.keys).to include("email", "external_id", "check_in_page_url")
      end

      it 'returns a valid interview url' do
        applicant = {
          first_name: "Peter",
          last_name: "Pan",
          email: "peter.pan#{Faker::Number.number(digits: 8)}@gmail.com"
        }

        applicant = service.create(applicant)
        url = applicant["check_in_page_url"]

        expect( url =~ /\A#{URI::regexp(['https'])}\z/ ).to eq 0
      end

      context 'existing interview' do

        it 'returns an exception' do
          applicant = {
            first_name: "Peter",
            last_name: "Pan",
            email: "peter.pan#{Faker::Number.number(digits: 8)}@gmail.com"
          }

          service.create(applicant) # first time works
          expect{ service.create(applicant) }.to raise_error(Kira::Error) # second time will raise error
        end

      end

      context "invalid email" do

        it "raises an exception" do
          applicant = {
            first_name: "Peter #{Faker::Number.number(digits: 10)}",
            last_name: "Pan #{Faker::Number.number(digits: 10)}",
            email: "8wh4iosefkjnc"
          }

          expect{ service.create(applicant) }.to raise_error(Kira::Error)
        end

      end

    end

  end
end
