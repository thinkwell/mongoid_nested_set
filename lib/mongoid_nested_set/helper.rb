module Mongoid::Acts::NestedSet

  module Helper

    def nested_set_options(class_or_item, mover = nil)
      if class_or_item.is_a? Array
        items = class_or_item.reject { |e| !e.root? }
      else
        class_or_item = class_or_item.roots if class_or_item.respond_to?(:scoped)
        items = Array(class_or_item)
      end
      result = []
      items.each do |root|
        result += root.class.associate_parents(root.self_and_descendants).map do |i|
          if mover.nil? || mover.new_record? || mover.move_possible?(i)
            [yield(i), i.id]
          end
        end.compact
      end
      result
    end
    
  end

end