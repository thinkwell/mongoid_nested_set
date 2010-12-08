module Mongoid::Acts::NestedSet
  module Matchers

    def have_nestedset_pos(lft, rgt, options = {})
      NestedSetPosition.new(lft, rgt, options)
    end

    class NestedSetPosition

      def initialize(lft, rgt, options)
        @lft = lft
        @rgt = rgt
        @options = options
      end

      def matches?(node)
        @node = node
        !!(
          node.respond_to?('left') && node.respond_to?('right') &&
          node.left == @lft &&
          node.right == @rgt
        )
      end

      def description
        "have position {left: #{@lft}, right: #{@rgt}}"
      end

      def failure_message_for_should
        sprintf("expected nested set position: {left: %2s, right: %2s}\n" +
                "                         got: {left: %2s, right: %2s}",
          @lft,
          @rgt,
          @node.respond_to?('left')  ? @node.left  : '?',
          @node.respond_to?('right') ? @node.right : '?'
        )
      end

      def failure_message_for_should_not
        sprintf("expected nested set to not have position: {left: %2s, right: %2s}", @lft, @rgt)
      end

    end

  end
end
