
class ShapeNode
  include Mongoid::Document
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
