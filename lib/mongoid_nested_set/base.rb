module Mongoid
  module Acts
    module NestedSet
      module Base
        def self.included(base)
          base.extend(SingletonMethods)
        end

        # This acts provides Nested Set functionality.  Nested Set is a smart way to implement
        # an _ordered_ tree, with the added feature that you can select the children and all of
        # their descendants with a single query.  The drawback is that insertion or move need
        # multiple queries.  But everything is done here by this module!
        #
        # Nested sets are appropriate each time you want either an ordered tree (menus,
        # commercial categories) or an efficient way of querying big trees (threaded posts).
        #
        # == API
        #
        # Method names are aligned with acts_as_tree as much as possible to make replacement
        # from one by another easier.
        #
        #   item.children.create(:name => 'child1')
        #
        module SingletonMethods
          # Configuration options are:
          #
          # * +:parent_field+ - field name to use for keeping the parent id (default: parent_id)
          # * +:left_field+ - field name for left boundary data, default 'lft'
          # * +:right_field+ - field name for right boundary data, default 'rgt'
          # * +:scope+ - restricts what is to be considered a list.  Given a symbol, it'll attach
          #   "_id" (if it hasn't been already) and use that as the foreign key restriction.  You
          #   can also pass an array to scope by multiple attributes
          # * +:dependent+ - behavior for cascading destroy.  If set to :destroy, all the child
          #   objects are destroyed alongside this object by calling their destroy method.  If set
          #   to :delete_all (default), all the child objects are deleted without calling their
          #   destroy method.
          #
          # See Mongoid::Acts::NestedSet::ClassMethods for a list of class methods and
          # Mongoid::Acts::NestedSet::InstanceMethods for a list of instance methods added to
          # acts_as_nested_set models
          def acts_as_nested_set(options = {})
            options = {
              :parent_field => 'parent_id',
              :left_field => 'lft',
              :right_field => 'rgt',
              :dependent => :delete_all, # or :destroy
            }.merge(options)

            if options[:scope].is_a?(Symbol) && options[:scope].to_s !~ /_id$/
              options[:scope] = "#{options[:scope]}_id".intern
            end

            class_attribute :acts_as_nested_set_options, :instance_writer => false
            self.acts_as_nested_set_options = options

            unless self.is_a?(ClassMethods)
              include Comparable
              include Fields
              include InstanceMethods

              extend Fields
              extend ClassMethods

              field left_field_name, :type => Integer
              field right_field_name, :type => Integer
              field :depth, :type => Integer

              references_many :children, :class_name => self.name, :foreign_key => parent_field_name, :inverse_of => :parent
              referenced_in   :parent,   :class_name => self.name, :foreign_key => parent_field_name

              if accessible_attributes.blank?
                attr_protected left_field_name.intern, right_field_name.intern
              end

              # no assignment to structure fields
              [left_field_name, right_field_name].each do |field|
                module_eval <<-"end_eval", __FILE__, __LINE__
                  def #{field}=(x)
                    raise NameError, "Unauthorized assignment to #{field}: it's an internal field handled by acts_as_nested_set code, use move_to_* methods instead.", "#{field}"
                  end
                end_eval
              end

              scope :roots, lambda {
                where(parent_field_name => nil).asc(left_field_name)
              }
              scope :leaves, lambda {
                where("this.#{quoted_right_field_name} - this.#{quoted_left_field_name} == 1").asc(left_field_name)
              }
              scope :with_depth, proc {|level| where(:depth => level).asc(left_field_name)}

            end
          end
        end


        module ClassMethods

          # Returns the first root
          def root
            roots.first
          end

          def valid?
            left_and_rights_valid? && no_duplicates_for_fields? && all_roots_valid?
          end

          def left_and_rights_valid?
            # TODO
            true
          end

          def no_duplicates_for_fields?
            # TODO
            true
          end

          # Wrapper for each_root_valid? that can deal with scope
          def all_roots_valid?
            # TODO
            true
          end

          def each_root_valid?(roots_to_validate)
            left = right = 0
            roots_to_validate.all? do |root|
              (root.left > left && root.right > right).tap do
                left = root.left
                right = root.right
              end
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

        protected

          def without_self(scope)
            scope.where(:_id.ne => self.id)
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

        end
      end # Base
    end # NestedSet
  end # Acts
end # Mongoid
