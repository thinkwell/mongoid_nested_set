require "#{File.dirname(__FILE__)}/test_document"

class ShapeNode
  include Mongoid::Document
  include Mongoid::Acts::NestedSet::TestDocument
  acts_as_nested_set

  field :name

  def test_set_attributes(attrs)
    @attributes.update(attrs)
    self
  end

  def self.test_set_dependent_option(val)
    self.acts_as_nested_set_options[:dependent] = val
  end
end
