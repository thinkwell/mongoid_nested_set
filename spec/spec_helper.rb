$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rr'
require 'mongoid'
require 'mongoid_nested_set'
require 'remarkable/mongoid'
require 'database_cleaner'

module Mongoid::Acts::NestedSet::Matchers
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/models/*.rb"].each {|file| require file }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].each {|file| require file }

Mongoid.configure do |config|
  name = "mongoid_nested_set_test"
  host = "localhost"
  config.allow_dynamic_fields = false
  #config.master = Mongo::Connection.new(host, nil, :logger => Logger.new($stdout)).db(name)
  config.master = Mongo::Connection.new.db(name)
  # config.slaves = [
    # Mongo::Connection.new(host, 27018, :slave_ok => true).db(name)
  # ]
end

RSpec.configure do |config|
  config.mock_with :rr
  config.include(Mongoid::Acts::NestedSet::Matchers)

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.orm = "mongoid"
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
