require 'rubygems'
require 'faker'
require 'webmock/rspec'
require 'vcr'

ROOT = Dir.pwd

require "#{ROOT}/lib/kira"

# Credentials are only used when re-recording cassettes. For replay, the
# values are scrubbed out of the committed cassettes via filter_sensitive_data.
KIRA_INTERVIEW_ID = ENV.fetch('KIRA_INTERVIEW_ID', 'fqvjnY').freeze
KIRA_TOKEN        = ENV.fetch('KIRA_TOKEN',        'fixture-token').freeze
KIRA_SECRET       = ENV.fetch('KIRA_SECRET',       'fixture-secret').freeze

VCR.configure do |c|
  c.cassette_library_dir = File.expand_path('cassettes', __dir__)
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: :once }

  c.filter_sensitive_data('<KIRA_TOKEN>')  { KIRA_TOKEN }
  c.filter_sensitive_data('<KIRA_SECRET>') { KIRA_SECRET }
end

# Block all net access except the Kira host. Cassettes serve responses on
# playback; the allow-list only matters during a re-record.
WebMock.disable_net_connect!(allow: 'app.kiratalent.com')
