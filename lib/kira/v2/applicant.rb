class Kira::V2::Applicant
  BASE_URL = 'https://app.kiratalent.com/api'

  def initialize(interview_id, token)
    @interview_id, @token = interview_id, token
  end

  def create(applicant)

    url = "#{BASE_URL}/interviews/#{@interview_id}/applicants/"

    res = conn.post do |req|
      req.url url
      req.headers["Authorization"] = " Token #{@token}"
      req.headers["Accept"] = "application/vnd.kiratalent.v2+json"
      req.headers["Content-Type"] = "application/json"
      req.body = applicant.to_json
    end

    response = JSON.parse(res.body)
    res.success? ? response : handle_error(response)
  end

  private

    def conn
      @conn ||= Faraday.new(BASE_URL)
    end

    def handle_error(response)
      raise Kira::Error.new(response)
    end

end
