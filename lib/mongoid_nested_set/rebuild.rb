module Mongoid::Acts::NestedSet

  module Rebuild

    # Rebuilds the left & rights if unset or invalid.  Also very useful for converting from acts_as_tree.
    # Warning: Very expensive!
    def rebuild!(options = {})
      # Don't rebuild a valid tree.
      return true if valid?

      scope = lambda{ |node| {} }
      if acts_as_nested_set_options[:scope]
        scope = lambda { |node| node.nested_set_scope.scoped }
      end
      indices = {}

      set_left_and_rights = lambda do |node|
        # set left
        left = (indices[scope.call(node)] += 1)
        # find
        node.nested_set_scope.where(parent_field_name => node.id).asc(left_field_name).asc(right_field_name).each { |n| set_left_and_rights.call(n) }
        # set right
        right = (indices[scope.call(node)] += 1)

        node.class.collection.update(
          {:_id => node.id},
          {"$set" => {left_field_name => left, right_field_name => right}},
          {:safe => true}
        )
      end

      # Find root node(s)
      root_nodes = self.where(parent_field_name => nil).asc(left_field_name).asc(right_field_name).asc(:_id).each do |root_node|
        # setup index for this scope
        indices[scope.call(root_node)] ||= 0
        set_left_and_rights.call(root_node)
      end
    end

  end
end
