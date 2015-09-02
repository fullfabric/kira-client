describe Kira::Applicant do

  let ( :credentials ) { { key: 'ddc6ced6898b40f8b90aecb55c363824', secret: 'c73675c025034db8a4deaad8513a8721' } }

  let ( :client ) { Kira::Auth.new(credentials) }

  context 'interview' do

    let ( :interview_id ) { '7267a9798ac740f0bd267651da31baf1' }
    let ( :token ) { client.access_token }

    let!( :service ) { Kira::Applicant.new(interview_id, token) }

    context 'find an applicant' do

      it 'by email' do

        response = service.find_by_email('peter.pan@arealdomain.com')

        expected_keys = [ 'completed_interview', 'embeddable_responses', 'id', 'interview_url', 'number_of_practice_attempts', 'number_of_responses', 'review_url' ].to_set

        expect( response.keys.to_set ).to eq expected_keys

      end

      context 'applicant does not exist' do

        it 'returns false' do
          expect(service.find_by_email('idonotexist@example.com')).to be false
        end

      end

    end

    context 'creating an applicant' do

      context 'passing an external id' do

        it 'returns external id' do

          params = {
            first_name: 'Peter',
            last_name: 'Pan',
            email: "peter.pan#{Faker::Number.number(8)}@gmail.com",
            external_id: '55e6abc4cc23c4351e0001d2'
          }

        applicant = service.create(params)

        expect( applicant['external_id'] ).to eq '55e6abc4cc23c4351e0001d2'

        end

      end

      it 'returns an applicant' do

        applicant = {
          first_name: "Peter",
          last_name: "Pan",
          email: "peter.pan#{Faker::Number.number(8)}@gmail.com"
        }

        applicant = service.create(applicant)

        expect( applicant.keys ).to eq [ 'email', 'external_id', 'interview_url' ]


      end

      it 'returns a valid interview url' do

        applicant = {
          first_name: "Peter",
          last_name: "Pan",
          email: "peter.pan#{Faker::Number.number(8)}@gmail.com"
        }

        applicant = service.create(applicant)
        url = applicant['interview_url']

        expect( url =~ /\A#{URI::regexp(['https'])}\z/ ).to eq 0

      end

      context 'existing interview' do

        it 'returns an exception' do

          applicant = {
            first_name: "Peter",
            last_name: "Pan",
            email: "peter.pan#{Faker::Number.number(8)}@gmail.com"
          }

          url = service.create(applicant) # first time works

          expect{ service.create(applicant) }.to raise_error Kira::ApplicantError::Exists

        end

      end

      context 'invalid email' do

        it 'raises an exception' do

          applicant = {
            first_name: "Peter #{Faker::Number.number(10)}",
            last_name: "Pan #{Faker::Number.number(10)}",
            email: "peter.pan#{Faker::Number.number(5)}@example.com"
          }

          expect{ service.create(applicant) }.to raise_error(Kira::Error)

        end

      end

    end

  end
end
