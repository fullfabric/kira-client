module Kira
  class Error < RuntimeError; end

  module ApplicantError
    class Exists < Kira::Error; end
  end

end
