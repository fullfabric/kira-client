class Kira::V2::Applicants
  include Contracts

  def initialize(client, interview_id)
    @client, @interview_id = client, interview_id
  end

  Contract KeywordArgs[
    first_name: String,
    last_name: String,
    email: String,
    external_id: Optional[String]
  ] => Hash
  def create(first_name:, last_name:, email:, external_id: nil)
    body = { first_name: first_name, last_name: last_name, email: email }
    body[:external_id] = external_id if external_id

    @client.request(:post, "/interviews/#{@interview_id}/applicants/", body: body)
  end
end
