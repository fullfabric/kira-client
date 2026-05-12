class Kira::V2::Interview
  def initialize(client, id)
    @client, @id = client, id
  end

  def applicants
    @applicants ||= Kira::V2::Applicants.new(@client, @id)
  end

  def webhooks
    @webhooks ||= Kira::V2::Webhooks.new(@client, @id)
  end
end
