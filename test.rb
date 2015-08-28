class TestKira

  def initialize
    @base_url = 'https://app.kiratalent.com/api'
    @interview_id = '7267a9798ac740f0bd267651da31baf1'
  end

  def conn
    @conn ||= Faraday.new(@base_url)
  end

  def access_token

    @access_token ||= begin

      data = { client_key: 'ddc6ced6898b40f8b90aecb55c363824', client_secret: 'c73675c025034db8a4deaad8513a8721', grant_type: 'client_credentials' }

      response = conn.post "#{@base_url}/oauth/access_token", data
      token_request = JSON.parse(response.body)
      # access_token = token_request['access_token']
      # refresh_token = token_request['refresh_token']
      token_request['access_token']

    end

  end

  # data = { refresh_token: refresh_token, grant_type: 'refresh_token' }
  # response = conn.post "#{@base_url}/oauth/refresh_token", data


  def add_applicant

    data = { applicants: [ { email: 'peter.pan@arealdomain.com', first_name: 'Peter', last_name: 'Pan' } ] }

    url = "#{@base_url}/v1/interview/#{@interview_id}/applicants/"

    conn.post do |req|
      req.url url
      req.headers['Authorization'] = " Bearer #{access_token}"
      req.body = data.to_json
    end

  end

  def get_applicant(email)

    url = "/api/v1/interview/#{@interview_id}/applicant_status/#{email}/"
    JSON.parse conn.get(url, { token: access_token }).body

  end

  def list_interviews
    url = "#{@base_url}/v1/interview/"
    JSON.parse conn.get(url, { token: access_token }).body
  end

end
