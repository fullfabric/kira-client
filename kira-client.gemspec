Gem::Specification.new do |s|
  s.name        = "kira-client"
  s.version     = "3.1.1"
  s.date        = "2026-05-26"
  s.summary     = "Kira Client"
  s.description = "Client to interact with the Kira API"
  s.authors     = ["Luis Correa d'Almeida"]
  s.email       = "luis@fullfabric.com"
  s.files       = Dir["lib/**/*.rb", "README.md", "CHANGELOG.md", "LICENSE*"]
  s.homepage    = "http://rubygems.org/gems/kira-client"
  s.license     = "MIT"

  s.required_ruby_version = ">= 3.0"

  s.add_dependency "contracts"
  s.add_dependency "faraday", "~> 2.13"
end
