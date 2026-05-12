Gem::Specification.new do |s|
  s.name        = "kira-client"
  s.version     = "2.0.0"
  s.date        = "2020-10-27"
  s.summary     = "Kira Client"
  s.description = "Client to interact with the Kira API"
  s.authors     = ["Luis Correa d'Almeida"]
  s.email       = "luis@fullfabric.com"
  s.files       = ["lib/kira-client.rb"]
  s.homepage    = "http://rubygems.org/gems/kira-client"
  s.license     = "MIT"

  s.required_ruby_version = ">= 3.0"

  s.add_dependency "contracts"
  s.add_dependency "faraday", "~> 2.0"
end
