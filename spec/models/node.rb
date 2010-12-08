
class Node
  include Mongoid::Document
  acts_as_nested_set :scope => :root_id

  field :name
  field :root_id, :type => Integer

  def test_set_attributes(attrs)
    @attributes.update(attrs)
    self
  end
end
