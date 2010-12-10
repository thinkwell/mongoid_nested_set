module Mongoid::Acts::NestedSet

  module Validation

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

  end
end
