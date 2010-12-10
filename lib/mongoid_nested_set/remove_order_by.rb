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

