class KiraClient::Applicant

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
    raise KiraClient::Error if response['failed'].size > 0

    response['added'][0]['interview_url']

  end

  def find_by_email(email)
    url = "/api/v1/interview/#{@interview_id}/applicant_status/#{email}/"
    JSON.parse conn.get(url, { token: @token }).body
  end

  private

    def conn
      @conn ||= Faraday.new(BASE_URL)
    end


end
