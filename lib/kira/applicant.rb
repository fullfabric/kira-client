class Kira::Applicant

  BASE_URL = 'https://app.kiratalent.com/api'

  def initialize interview_id, token
    @interview_id, @token = interview_id, token
  end

  def create(applicant)

    url = "#{BASE_URL}/v1/interview/#{@interview_id}/applicants/"

    data = { applicants: [ applicant ] }

    res = conn.post do |req|
      req.url url
      req.headers['Authorization'] = " Bearer #{@token}"
      req.body = data.to_json
    end

    response = JSON.parse(res.body)

    handle_error(response)

    response['added'][0]

  end

  def find_by_email(email)

    url = "/api/v1/interview/#{@interview_id}/applicant_status/#{email}/"
    body = conn.get(url, { token: @token }).body

    # http://api.rubyonrails.org/classes/String.html
    /\A[[:space:]]*\z/ === body ? false : JSON.parse(body)

  end

  private

    def conn
      @conn ||= Faraday.new(BASE_URL)
    end

    def handle_error(response)

      if response['failed'].size > 0

        error = response['failed'][0]

        case error['error']
        when 'EXIST'
          raise Kira::ApplicantError::Exists
        else
          raise Kira::Error
        end

      end

    end


end
