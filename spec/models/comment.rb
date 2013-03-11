class Comment
  include Mongoid::Document
  acts_as_nested_set :scope => :commentable

  field :body
  belongs_to :commentable, :polymorphic => true
  
end