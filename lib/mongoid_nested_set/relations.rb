module Mongoid::Acts::NestedSet

  module Relations

    # Returns root
    def root
      self_and_ancestors.first
    end


    # Returns the array of all parents and self
    def self_and_ancestors
      nested_set_scope.where(
        left_field_name => {"$lte" => left},
        right_field_name => {"$gte" => right}
      )
    end


    # Returns an array of all parents
    def ancestors
      without_self self_and_ancestors
    end


    # Returns the array of all children of the parent, including self
    def self_and_siblings
      nested_set_scope.where(parent_field_name => parent_id)
    end


    # Returns the array of all children of the parent, except self
    def siblings
      without_self self_and_siblings
    end


    # Returns a set of all of its nested children which do not have children
    def leaves
      descendants.where("this.#{right_field_name} - this.#{left_field_name} == 1")
    end


    # Returns the level of this object in the tree
    # root level is 0
    def level
      parent_id.nil? ? 0 : ancestors.count
    end


    # Returns a set of itself and all of its nested children
    def self_and_descendants
      nested_set_scope.where(
        left_field_name => {"$gte" => left},
        right_field_name => {"$lte" => right}
      )
    end


    # Returns a set of all of its children and nested children
    def descendants
      without_self self_and_descendants
    end


    def is_descendant_of?(other)
      other.left < self.left && self.left < other.right && same_scope?(other)
    end
    alias :descendant_of? is_descendant_of?


    def is_or_is_descendant_of?(other)
      other.left <= self.left && self.left < other.right && same_scope?(other)
    end


    def is_ancestor_of?(other)
      self.left < other.left && other.left < self.right && same_scope?(other)
    end
    alias :ancestor_of? is_ancestor_of?


    def is_or_is_ancestor_of?(other)
      self.left <= other.left && other.left < self.right && same_scope?(other)
    end


    # Find the first sibling to the left
    def left_sibling
      siblings.where(left_field_name => {"$lt" => left}).remove_order_by.desc(left_field_name).first
    end


    # Find the first sibling to the right
    def right_sibling
      siblings.where(left_field_name => {"$gt" => left}).asc(left_field_name).first
    end

  end
end
