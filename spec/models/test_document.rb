module Mongoid::Acts::NestedSet

  module TestDocument

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end


    module ClassMethods

      def test_set_dependent_option(val)
        self.acts_as_nested_set_options[:dependent] = val
      end

    end


    module InstanceMethods

      def test_set_attributes(attrs)
        attrs.each do |key, val|
          if Mongoid.allow_dynamic_fields ||
              fields.keys.any? { |k| k.to_s == key.to_s } ||
              associations.any? { |a| a[0].to_s == key.to_s || a[1].foreign_key.to_s == key.to_s }
            @attributes[key] = val
          end
        end
        self
      end

    end
  end
end
