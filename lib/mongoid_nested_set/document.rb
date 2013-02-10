module Mongoid::Acts::NestedSet

  module Document

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end


    module ClassMethods

      include Rebuild
      include Validation
      include Fields

      # Returns the first root
      def root
        roots.first
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


      # Iterates over tree elements with ancestors.
      # Only accepts default ordering, ordering by an other field than lft
      # does not work.  This is much more efficient than calling ancestors for
      # each object because it doesn't require any additional database queries.
      #
      # Example:
      #   Category.each_with_ancestors(Category.root.self_and_descendants) do |o, ancestors|
      #
      def each_with_ancestors(objects)
        ancestors = nil
        last_parent = nil
        objects.each do |o|
          if ancestors == nil
            ancestors = o.root? ? [] : o.ancestors.entries
          end
          if ancestors.empty? || o.parent_id != ancestors.last.id
            # we are on a new level, did we descend or ascend?
            if ancestors.any? {|a| a.id == o.parent_id}
              # ascend
              ancestors.pop while (!ancestors.empty? && ancestors.last.id != o.parent_id)
            elsif !o.root?
              # descend
              ancestors << last_parent
            end
          end
          yield(o, ancestors)
          last_parent = o
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

      def associate_parents(objects)
        if objects.all?{|o| o.respond_to?(:association)}
          id_indexed = objects.index_by(&:id)
          objects.each do |object|
            if !(association = object.association(:parent)).loaded? && (parent = id_indexed[object.parent_id])
              association.target = parent
              association.set_inverse_instance(parent)
            end
          end
        else
          objects
        end
      end

    end




    module InstanceMethods

      include Comparable
      include Relations
      include Update
      include Fields

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


      # Returns true if outline numbering is supported
      def outline_numbering?
        !!outline_number_field_name
      end


      # order by left field
      def <=>(x)
        left <=> x.left
      end


      # Redefine to act like active record
      def ==(comparison_object)
        comparison_object.equal?(self) ||
          (comparison_object.instance_of?(scope_class) &&
           comparison_object.id == id &&
           !comparison_object.new_record?)
      end


      # Check if other model is in the same scope
      def same_scope?(other)
        Array(acts_as_nested_set_options[:scope]).all? do |attr|
          self.send(attr) == other.send(attr)
        end
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
        scope_class.criteria.where(conditions).asc(left_field_name)
      end



      protected

      def without_self(scope)
        scope.where(:_id.ne => self.id)
      end


      # reload left, right, and parent
      def reload_nested_set
        reload
      end

    end
  end # Document
end # Mongoid::Acts::NestedSet
