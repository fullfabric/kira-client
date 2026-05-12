require 'rubygems'
require 'faker'
require 'webmock/rspec'

ROOT = Dir.pwd

require "#{ROOT}/lib/kira"

WebMock.disable_net_connect!
