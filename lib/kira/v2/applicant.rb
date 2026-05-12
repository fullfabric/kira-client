class Kira::V2::Applicant
  include Contracts
  include Kira::V2::Client

  Contract String, String => Any
  def initialize(interview_id, token)
    @interview_id, @token = interview_id, token
  end

  Contract Hash => Hash
  def create(applicant)
    request(:post, "/interviews/#{@interview_id}/applicants/", body: applicant)
  end
end
