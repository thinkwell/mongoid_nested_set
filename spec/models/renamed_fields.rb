
class RenamedFields
  include Mongoid::Document
  acts_as_nested_set :parent_field => 'mother_id', :left_field => 'red', :right_field => 'black'

  field :name
end
