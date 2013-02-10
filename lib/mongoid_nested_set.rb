
require 'mongoid_nested_set/remove_order_by'

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
module Mongoid
  module Acts
    module NestedSet
      require 'mongoid_nested_set/base'
      autoload :Document,      'mongoid_nested_set/document'
      autoload :Fields,        'mongoid_nested_set/fields'
      autoload :Rebuild,       'mongoid_nested_set/rebuild'
      autoload :Relations,     'mongoid_nested_set/relations'
      autoload :Update,        'mongoid_nested_set/update'
      autoload :Validation,    'mongoid_nested_set/validation'
      autoload :OutlineNumber, 'mongoid_nested_set/outline_number'

      def self.included(base)
        base.extend(Base)
      end
    end
  end
end


# Enable the acts_as_nested_set method
Mongoid::Document::ClassMethods.send(:include, Mongoid::Acts::NestedSet::Base)

# Enable helper
if defined?(ActionView)
  require 'mongoid_nested_set/helper'
  ActionView::Base.send :include, Mongoid::Acts::NestedSet::Helper
end