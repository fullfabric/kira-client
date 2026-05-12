source 'https://rubygems.org'

gemspec

# Pinned for dev/CI parity with the backend (currently on Faraday 2.7.x).
# SQ2-1047 lifts this and the matching gemspec floor in lockstep.
gem 'faraday', '~> 2.8.0'

group :development, :test do
  gem 'rspec', '>= 3'
  gem 'guard-rspec', '>= 2.8'
  gem 'json_spec'
  gem 'faker'
end
