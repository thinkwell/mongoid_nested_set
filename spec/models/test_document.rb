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
        @attributes.update(attrs)
        self
      end

    end
  end
end
