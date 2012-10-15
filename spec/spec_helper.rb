$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rr'
require 'mongoid'
require 'mongoid_nested_set'
require 'remarkable/mongoid'

if ENV['COVERAGE'] == 'yes'
  require 'simplecov'
  require 'simplecov-rcov'

  class SimpleCov::Formatter::MergedFormatter
    def format(result)
      SimpleCov::Formatter::HTMLFormatter.new.format(result)
      SimpleCov::Formatter::RcovFormatter.new.format(result)
    end
  end

  SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
  SimpleCov.start 
end

module Mongoid::Acts::NestedSet::Matchers
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/models/*.rb"].each {|file| require file }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].each {|file| require file }

Mongoid.configure do |config|
  config.connect_to("mongoid_nested_set_test")
  config.allow_dynamic_fields = false
end

RSpec.configure do |config|
  config.mock_with :rr
  config.include(Mongoid::Acts::NestedSet::Matchers)

  config.after(:each) do
    Mongoid::Config.purge!
  end
end
