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

  s.add_development_dependency "awesome_print"
  s.add_development_dependency "better_errors"
  s.add_development_dependency "binding_of_caller"
  s.add_development_dependency "pry-byebug"

  s.add_development_dependency "rspec", [ ">= 3" ]
  s.add_development_dependency "guard-rspec", [ ">= 2.8" ]
  # s.add_development_dependency "rspec-rails"
  # s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "spork"
  s.add_development_dependency "guard-spork"
  s.add_development_dependency "json_spec"
  s.add_development_dependency "faker"

end
