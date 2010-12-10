module Mongoid::Acts::NestedSet

  module Base

    module ClassMethods

      # Returns the first root
      def root
        roots.first
      end

      # Warning: Very expensive!  Do not use unless you know what you are doing.
      # This method is only useful for determining if the entire tree is valid
      def valid?
        left_and_rights_valid? && no_duplicates_for_fields? && all_roots_valid?
      end

      # Warning: Very expensive!  Do not use unless you know what you are doing.
      def left_and_rights_valid?
        all.detect { |node|
          node.send(left_field_name).nil? ||
            node.send(right_field_name).nil? ||
            node.send(left_field_name) >= node.send(right_field_name) ||
            !node.parent.nil? && (
              node.send(left_field_name) <= node.parent.send(left_field_name) ||
              node.send(right_field_name) >= node.parent.send(right_field_name)
          )
        }.nil?
      end

      # Warning: Very expensive!  Do not use unless you know what you are doing.
      def no_duplicates_for_fields?
        roots.group_by{|record| scope_field_names.collect{|field| record.send(field.to_sym)}}.all? do |scope, grouped_roots|
          [left_field_name, right_field_name].all? do |field|
            grouped_roots.first.nested_set_scope.only(field).aggregate.all? {|c| c['count'] == 1}
          end
        end
      end

      # Wrapper for each_root_valid? that can deal with scope
      # Warning: Very expensive!  Do not use unless you know what you are doing.
      def all_roots_valid?
        if acts_as_nested_set_options[:scope]
          roots.group_by{|record| scope_field_names.collect{|field| record.send(field.to_sym)}}.all? do |scope, grouped_roots|
            each_root_valid?(grouped_roots)
          end
        else
          each_root_valid?(roots)
        end
      end

      def each_root_valid?(roots_to_validate)
        right = 0
        roots_to_validate.all? do |root|
          (root.left > right && root.right > right).tap do
            right = root.right
          end
        end
      end

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

      def scope_condition_by_options(options)
        h = {}
        scope_string = Array(acts_as_nested_set_options[:scope]).reject{|s| !options.has_key?(s) }.each do |c|
          h[c] = options[c]
        end
        h
      end

      # Iterates over tree elements and determines the current level in the tree.
      # Only accepts default ordering, ordering by an other field than lft
      # does not work.  This method is much more efficient then calling level
      # because it doesn't require any additional database queries.
      # This method does not used the cached depth field.
      #
      # Example:
      #   Category.each_with_level(Category.root.self_and_descendants) do |o, level|
      #
      def each_with_level(objects)
        offset = nil
        path = [nil]
        objects.each do |o|
          if offset == nil
            offset = o.parent_id.nil? ? 0 : o.parent.level
          end
          if o.parent_id != path.last
            # we are on a new level, did we descend or ascend?
            if path.include?(o.parent_id)
              # remove wrong tailing path elements
              path.pop while path.last != o.parent_id
            else
              path << o.parent_id
            end
          end
          yield(o, path.length - 1 + offset)
        end
      end

      # Provides a chainable relation to select all descendants of a set of records,
      # excluding the record set itself.
      # Similar to parent.descendants, except this allows you to find all descendants
      # of a set of nodes, rather than being restricted to find the descendants of only
      # a single node.
      #
      # Example:
      #   parents = Category.roots.all
      #   parents_descendants = Category.where(:deleted => false).descendants_of(parents)
      #
      def descendants_of(parents)
        # TODO: Add root or scope?
        conditions = parents.map do |parent|
          {left_field_name => {"$gt" => parent.left}, right_field_name => {"$lt" => parent.right}}
        end
        where("$or" => conditions)
      end

      def before_move(*args, &block)
        set_callback :move, :before, *args, &block
      end

      def after_move(*args, &block)
        set_callback :move, :after, *args, &block
      end
    end


    # Mixed into both classes and instances to provide easy access to the field names
    module Fields
      def left_field_name
        acts_as_nested_set_options[:left_field]
      end

      def right_field_name
        acts_as_nested_set_options[:right_field]
      end

      def parent_field_name
        acts_as_nested_set_options[:parent_field]
      end

      def scope_field_names
        Array(acts_as_nested_set_options[:scope])
      end

      def quoted_left_field_name
        # TODO
        left_field_name
      end

      def quoted_right_field_name
        # TODO
        right_field_name
      end

      def quoted_parent_field_name
        # TODO
        parent_field_name
      end

      def quoted_scope_field_names
        # TODO
        scope_field_names
      end
    end


    module InstanceMethods

      # Value fo the parent field
      def parent_id
        self[parent_field_name]
      end

      # Value of the left field
      def left
        self[left_field_name]
      end

      # Value of the right field
      def right
        self[right_field_name]
      end

      # Returns true if this is a root node
      def root?
        parent_id.nil?
      end

      # Returns true if this is a leaf node
      def leaf?
        #!new_record? && right - left == 1
        right - left == 1
      end

      # Returns true if this is a child node
      def child?
        !parent_id.nil?
      end

      # Returns true if depth is supported
      def depth?
        true
      end

      # order by left field
      def <=>(x)
        left <=> x.left
      end

      # Redefine to act like active record
      def ==(comparison_object)
        comparison_object.equal?(self) ||
          (comparison_object.instance_of?(self.class) &&
           comparison_object.id == id &&
           !comparison_object.new_record?)
      end

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

      # Check if other model is in the same scope
      def same_scope?(other)
        Array(acts_as_nested_set_options[:scope]).all? do |attr|
          self.send(attr) == other.send(attr)
        end
      end

      # Find the first sibling to the left
      def left_sibling
        siblings.where(left_field_name => {"$lt" => left}).remove_order_by.desc(left_field_name).first
      end

      # Find the first sibling to the right
      def right_sibling
        siblings.where(left_field_name => {"$gt" => left}).asc(left_field_name).first
      end

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

      def to_text
        self_and_descendants.map do |node|
          "#('*'*(node.level+1)} #{node.id} #{node.to_s} (#{node.parent_id}, #{node.left}, #{node.right})"
        end.join("\n")
      end

      # All nested set queries should use this nested_set_scope, which performs finds
      # using the :scope declared in the acts_as_nested_set declaration
      def nested_set_scope
        scopes = Array(acts_as_nested_set_options[:scope])
        conditions = scopes.inject({}) do |conditions,attr|
          conditions.merge attr => self[attr]
        end unless scopes.empty?
        self.class.criteria.where(conditions).asc(left_field_name)
      end

      protected

      def without_self(scope)
        scope.where(:_id.ne => self.id)
      end

      def store_new_parent
        @move_to_new_parent_id = send("#{parent_field_name}_changed?") ? parent_id : false
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
          self.class.delete_all(:conditions => c.selector)
        end

        # update lefts and rights for remaining nodes
        diff = right - left + 1
        self.class.collection.update(
          nested_set_scope.fuse(:where => {left_field_name => {"$gt" => right}}).selector,
          {"$inc" => { left_field_name => -diff }},
          {:safe => true, :multi => true}
        )
        self.class.collection.update(
          nested_set_scope.fuse(:where => {right_field_name => {"$gt" => right}}).selector,
          {"$inc" => { right_field_name => -diff }},
          {:safe => true, :multi => true}
        )

        # Don't allow multiple calls to destroy to corrupt the set
        self.skip_before_destroy = true
      end

      # reload left, right, and parent
      def reload_nested_set
        reload
      end

      def move_to(target, position)
        raise Mongoid::Errors::MongoidError, "You cannot move a new node" if self.new_record?

        res = run_callbacks :move do

          # No transaction support in MongoDB.
          # ACID is not guaranteed
          # TODO

          if target.is_a? self.class
            target.reload_nested_set
          elsif position != :root
            # load object if node is not an object
            target = nested_set_scope.find(target).first
          end
          self.reload_nested_set

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
          self.class.each_with_level(self_and_descendants) do |node, level|
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
    end
  end # Document
end # Mongoid::Acts::NestedSet
