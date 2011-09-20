require 'simplecov'
SimpleCov.start 'rails'
SimpleCov.use_merging false

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
end

require 'mocha'
require 'webmock/test_unit'
require 'asset_helpers'