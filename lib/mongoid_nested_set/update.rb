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
      maxright = nested_set_scope.remove_order_by.max(right_field_name) || 0
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

        old_parent = self[parent_field_name]
        new_parent = case position
                     when :child; target.id
                     when :root;  nil
                     else         target[parent_field_name]
                     end
        
        left, right     = [self[left_field_name], self[right_field_name]]
        width, distance = [right - left + 1, bound - left]
        edge            = bound > right ? bound - 1 : bound

        # there would be no change
        return self if left == edge || right == edge

        # moving backwards
        if distance < 0
          distance -= width
          left += width
        end

        scope_class.mongo_session.with(:safe => true) do |session|
          collection = session[scope_class.collection_name]
          scope = nested_set_scope.remove_order_by

          # allocate space for new move
          collection.find(
            scope.gte(left_field_name => bound).selector
          ).update_all("$inc" => { left_field_name => width })

          collection.find(
            scope.gte(right_field_name => bound).selector
          ).update_all("$inc" => { right_field_name => width })

          # move the nodes
          collection.find(
            scope.and(left_field_name => {"$gte" => left}, right_field_name => {"$lt" => left + width}).selector
          ).update_all("$inc" => { left_field_name => distance, right_field_name => distance })

          # remove the hole
          collection.find(
            scope.gt(left_field_name => right).selector
          ).update_all("$inc" => { left_field_name => -width })

          collection.find(
            scope.gt(right_field_name => right).selector
          ).update_all("$inc" => { right_field_name => -width })
        end

        self.mongoid_set(parent_field_name, new_parent)
        self.reload_nested_set
        self.update_self_and_descendants_depth

        if outline_numbering?
          if old_parent && old_parent != new_parent
            scope_class.where(:_id => old_parent).first.update_descendants_outline_number
          end
          if new_parent
            scope_class.where(:_id => new_parent).first.update_descendants_outline_number
          else
            update_self_and_descendants_outline_number
          end
          self.reload_nested_set
        end

        target.reload_nested_set if target
      end
      self
    end


    # Update cached level attribute
    def update_depth
      if depth?
        self.update_attribute(:depth, level)
      end
      self
    end


    # Update cached level attribute for self and descendants
    def update_self_and_descendants_depth
      if depth?
        scope_class.each_with_level(self_and_descendants) do |node, level|
          node.with(:safe => true).mongoid_set(:depth, level) unless node.depth == level
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
        c = nested_set_scope.where(left_field_name.to_sym.gt => left, right_field_name.to_sym.lt => right)
        scope_class.where(c.selector).delete_all
      end

      # update lefts and rights for remaining nodes
      diff = right - left + 1

      scope_class.with(:safe => true).where(
        nested_set_scope.where(left_field_name.to_sym.gt => right).selector
      ).inc(left_field_name, -diff)

      scope_class.with(:safe => true).where(
        nested_set_scope.where(right_field_name.to_sym.gt => right).selector
      ).inc(right_field_name, -diff)

      # Don't allow multiple calls to destroy to corrupt the set
      self.skip_before_destroy = true
    end

    # Compatibility wrapper for mongoid set method, should works with 3.x.x and
    # 4.x.x versions
    def mongoid_set(field, value)
      if method(:set).arity == 1
        set({field => value})
      else
        set(field, value)
      end
    end

  end
end
