module Mongoid::Acts::NestedSet

  module Update

    # Shorthand method for finding the left sibling and moving to the left of it
    def move_left
      move_to_left_of left_sibling
    end


    # Shorthand method for finding the right sibling and moving to the right of it
    def move_right
      move_to_right_of right_sibling
    end


    # Move the node to the left of another node (you can pass id only)
    def move_to_left_of(node)
      move_to node, :left
    end


    # Move the node to the right of another node (you can pass id only)
    def move_to_right_of(node)
      move_to node, :right
    end


    # Move the node to the child of another node (you can pass id only)
    def move_to_child_of(node)
      move_to node, :child
    end


    # Move the node to root nodes
    def move_to_root
      move_to nil, :root
    end


    def move_possible?(target)
      self != target && # Can't target self
        same_scope?(target) && # can't be in different scopes
        !((left <= target.left && right >= target.left) or (left <= target.right && right >= target.right))
    end



    protected

    def store_new_parent
      @move_to_new_parent_id = ((self.new_record? && parent_id) || send("#{parent_field_name}_changed?")) ? parent_id : false
      true # force callback to return true
    end


    def move_to_new_parent
      if @move_to_new_parent_id.nil?
        move_to_root
      elsif @move_to_new_parent_id
        move_to_child_of(@move_to_new_parent_id)
      end
    end


    # on creation, set automatically lft and rgt to the end of the tree
    def set_default_left_and_right
      maxright = nested_set_scope.max(right_field_name) || 0
      self[left_field_name] = maxright + 1
      self[right_field_name] = maxright + 2
      self[:depth] = 0
    end


    def move_to(target, position)
      raise Mongoid::Errors::MongoidError, "You cannot move a new node" if self.new_record?

      res = run_callbacks :move do

        # No transaction support in MongoDB.
        # ACID is not guaranteed
        # TODO

        if target.is_a? scope_class
          target.reload_nested_set
        elsif position != :root
          # load object if node is not an object
          target = nested_set_scope.where(:_id => target).first
        end
        self.reload_nested_set

        unless position == :root || target
          raise Mongoid::Errors::MongoidError, "Impossible move, target node cannot be found."
        end

        unless position == :root || move_possible?(target)
          raise Mongoid::Errors::MongoidError, "Impossible move, target node cannot be inside moved tree."
        end

        bound = case position
                when :child; target[right_field_name]
                when :left;  target[left_field_name]
                when :right; target[right_field_name] + 1
                when :root;  1
                else raise Mongoid::Errors::MongoidError, "Position should be :child, :left, :right or :root ('#{position}' received)."
                end

        if bound > self[right_field_name]
          bound = bound - 1
          other_bound = self[right_field_name] + 1
        else
          other_bound = self[left_field_name] - 1
        end

        # there would be no change
        return self if bound == self[right_field_name] || bound == self[left_field_name]

        # we have defined the boundaries of two non-overlapping intervals,
        # so sorting puts both the intervals and their boundaries in order
        a, b, c, d = [self[left_field_name], self[right_field_name], bound, other_bound].sort

        new_parent = case position
                     when :child; target.id
                     when :root;  nil
                     else         target[parent_field_name]
                     end

        # TODO: Worst case O(n) queries, improve?
        # MongoDB 1.9 may allow javascript in updates: http://jira.mongodb.org/browse/SERVER-458
        nested_set_scope.only(left_field_name, right_field_name, parent_field_name).remove_order_by.each do |node|
          updates = {}
          if (a..b).include? node.left
            updates[left_field_name] = node.left + d - b
          elsif (c..d).include? node.left
            updates[left_field_name] = node.left + a - c
          end

          if (a..b).include? node.right
            updates[right_field_name] = node.right + d - b
          elsif (c..d).include? node.right
            updates[right_field_name] = node.right + a - c
          end

          updates[parent_field_name] = new_parent if self.id == node.id

          node.class.collection.update(
            {:_id => node.id },
            {"$set" => updates},
            {:safe => true}
          ) unless updates.empty?
        end

        self.reload_nested_set
        self.update_self_and_descendants_depth
        target.reload_nested_set if target
      end
      self
    end


    # Update cached level attribute
    def update_depth
      if depth?
        self.update_attributes(:depth => level)
      end
      self
    end


    # Update cached level attribute for self and descendants
    def update_self_and_descendants_depth
      if depth?
        scope_class.each_with_level(self_and_descendants) do |node, level|
          node.class.collection.update(
            {:_id => node.id},
            {"$set" => {:depth => level}},
            {:safe => true}
          ) unless node.depth == level
        end
        self.reload
      end
      self
    end


    # Prunes a branch off of the tree, shifting all of the elements on the right
    # back to the left so the counts still work
    def destroy_descendants
      return if right.nil? || left.nil? || skip_before_destroy

      if acts_as_nested_set_options[:dependent] == :destroy
        descendants.each do |model|
          model.skip_before_destroy = true
          model.destroy
        end
      else
        c = nested_set_scope.fuse(:where => {left_field_name => {"$gt" => left}, right_field_name => {"$lt" => right}})
        scope_class.delete_all(:conditions => c.selector)
      end

      # update lefts and rights for remaining nodes
      diff = right - left + 1
      scope_class.collection.update(
        nested_set_scope.fuse(:where => {left_field_name => {"$gt" => right}}).selector,
        {"$inc" => { left_field_name => -diff }},
        {:safe => true, :multi => true}
      )
      scope_class.collection.update(
        nested_set_scope.fuse(:where => {right_field_name => {"$gt" => right}}).selector,
        {"$inc" => { right_field_name => -diff }},
        {:safe => true, :multi => true}
      )

      # Don't allow multiple calls to destroy to corrupt the set
      self.skip_before_destroy = true
    end

  end
end
