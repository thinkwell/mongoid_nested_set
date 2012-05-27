module Mongoid
  module Criterion
    module Ordering
      def remove_order_by
        @options[:sort] = nil
        self
      end
    end
  end

  class Criteria
    include Criterion::Ordering
  end
end

