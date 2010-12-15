module Mongoid::Acts::NestedSet

  module OutlineNumber

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end

    module ClassMethods

      # Iterates over tree elements and determines the current outline number in
      # the tree.
      # Only accepts default ordering, ordering by an other field than lft
      # does not work.
      # This method does not used the cached number field.
      #
      # Example:
      #   Category.each_with_outline_number(Category.root.self_and_descendants) do |o, level|
      #
      def each_with_outline_number(objects, parent_number=nil)
        objects = Array(objects) unless objects.is_a? Array

        stack = []
        last_num = parent_number
        objects.each_with_index do |o, i|
          if i == 0 && last_num == nil && !o.root?
            last_num = o.parent.outline_number
          end

          if stack.last.nil? || o.parent_id != stack.last[:parent_id]
            # we are on a new level, did we descend or ascend?
            if stack.any? { |h| h[:parent_id] == o.parent_id }
              # ascend
              stack.pop while stack.last[:parent_id] != o.parent_id
            else
              # descend
              stack << {:parent_id => o.parent_id, :parent_number => last_num, :siblings => []}
            end
          end

          if o.root? && !roots_have_outline_numbers?
            num = nil
          else
            num = o.send(:build_outline_number,
              o.root? ? '' : stack.last[:parent_number],
              o.send(:outline_number_sequence, stack.last[:siblings])
            )
          end
          yield(o, num)

          stack.last[:siblings] << o
          last_num = num
        end
      end


      def update_outline_numbers(objects, parent_number=nil)
        each_with_outline_number(objects, parent_number) do |o, num|
          o.update_attributes(outline_number_field_name => num)
        end
      end


      # Do root nodes have outline numbers
      def roots_have_outline_numbers?
        false
      end

    end

    module InstanceMethods

      def outline_number
        self[outline_number_field_name]
      end


      def update_outline_number
        self.class.update_outline_numbers(self)
      end


      def update_self_and_descendants_outline_number
        self.class.update_outline_numbers(self_and_descendants)
      end


      def update_descendants_outline_number
        self.class.update_outline_numbers(self.descendants, self.outline_number)
      end


      protected

      # Gets the outline sequence number for this node
      #
      # For example, if the parent's outline number is 1.2 and this is the
      # 3rd sibling this will return 3.
      #
      def outline_number_sequence(prev_siblings)
        prev_siblings.count + 1
      end


      # Constructs the full outline number
      #
      def build_outline_number(parent_number, sequence)
        if parent_number && parent_number != ''
          parent_number + outline_number_seperator + sequence.to_s
        else
          sequence.to_s
        end
      end

      def outline_number_seperator
        '.'
      end

    end
  end
end
