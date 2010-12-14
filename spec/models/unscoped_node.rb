require "#{File.dirname(__FILE__)}/test_document"

class UnscopedNode
  include Mongoid::Document
  include Mongoid::Acts::NestedSet::TestDocument
  acts_as_nested_set

  field :name
end
