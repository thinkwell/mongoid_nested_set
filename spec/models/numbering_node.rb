require "#{File.dirname(__FILE__)}/test_document"

class NumberingNode
  include Mongoid::Document
  include Mongoid::Acts::NestedSet::TestDocument
  acts_as_nested_set :scope => :root_id, :outline_number_field => 'number'

  field :name
  field :root_id, :type => Integer
end
