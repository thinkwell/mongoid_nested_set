module Mongoid::Acts::NestedSet

  # Mixed int both classes and instances to provide easy access to the field names
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


    def outline_number_field_name
      acts_as_nested_set_options[:outline_number_field]
    end


    def scope_field_names
      Array(acts_as_nested_set_options[:scope])
    end


    def scope_class
      acts_as_nested_set_options[:klass]
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
end
