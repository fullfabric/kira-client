class Kira::V2::Applicant
  include Contracts
  include Kira::V2::Client

  Contract String, String, KeywordArgs[base_url: Optional[String]] => Any
  def initialize(interview_id, token, base_url: nil)
    @interview_id, @token, @base_url = interview_id, token, base_url
  end

  Contract Hash => Hash
  def create(applicant)
    request(:post, "/interviews/#{@interview_id}/applicants/", body: applicant)
  end
end
