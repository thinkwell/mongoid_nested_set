require "#{File.dirname(__FILE__)}/test_document"

class Node
  include Mongoid::Document
  include Mongoid::Acts::NestedSet::TestDocument
  acts_as_nested_set :scope => :root_id

  field :name
  field :root_id, :type => Integer
end
