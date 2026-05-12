module Kira
  class Error < RuntimeError
    attr_reader :status, :body, :parsed

    def initialize(message = nil, status: nil, body: nil, parsed: nil)
      @status = status
      @body   = body
      @parsed = parsed
      super(message || _default_message)
    end

    private

    def _default_message
      if @parsed.is_a?(Hash) && @parsed["detail"]
        @parsed["detail"]
      elsif @body && !@body.empty?
        "Kira API error #{@status}: #{@body[0, 200]}"
      else
        "Kira API error #{@status}"
      end
    end
  end

  module ApplicantError
    class Exists < Kira::Error; end
  end
end
