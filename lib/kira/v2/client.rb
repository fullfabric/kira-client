class Kira::V2::Client
  include Contracts

  BASE_URL = 'https://app.kiratalent.com/api'.freeze

  Contract KeywordArgs[token: String, base_url: Optional[String]] => Any
  def initialize(token:, base_url: nil)
    @token = token
    @base_url = base_url
  end

  Contract String => Kira::V2::Interview
  def interview(id)
    Kira::V2::Interview.new(self, id)
  end

  # Internal — called by resource classes. Public so resources can reach it.
  def request(method, path, body: nil)
    res = conn.public_send(method) do |req|
      req.url "#{base_url}#{path}"
      req.headers.update(auth_headers)
      req.body = body.to_json if body
    end

    handle_response(res)
  end

  private

  def base_url
    @base_url || BASE_URL
  end

  def conn
    @conn ||= Faraday.new(base_url)
  end

  def auth_headers
    {
      "Authorization" => "Token #{@token}",
      "Accept"        => "application/vnd.kiratalent.v2+json",
      "Content-Type"  => "application/json"
    }
  end

  def handle_response(res)
    parsed = safe_json_parse(res.body)
    return parsed if res.success?

    raise _build_error(res, parsed)
  end

  def safe_json_parse(body)
    JSON.parse(body)
  rescue JSON::ParserError
    nil
  end

  def _build_error(res, parsed)
    klass = _applicant_already_exists?(res, parsed) ? Kira::ApplicantError::Exists : Kira::Error
    klass.new(status: res.status, body: res.body, parsed: parsed)
  end

  def _applicant_already_exists?(res, parsed)
    res.status == 409 &&
      parsed.is_a?(Hash) &&
      parsed["detail"].to_s.include?("already been registered")
  end
end
