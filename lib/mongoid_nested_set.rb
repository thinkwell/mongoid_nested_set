module Mongoid
  module Acts
    module NestedSet
      autoload :Base, 'mongoid_nested_set/base'
    end
  end
end


module Mongoid
  module Criterion
    module Optional
      def remove_order_by
        @options[:sort] = nil
        self
      end
    end
  end
end


# Enable the acts_as_nested_set method
Mongoid::Document::ClassMethods.send(:include, Mongoid::Acts::NestedSet::Base::SingletonMethods)
