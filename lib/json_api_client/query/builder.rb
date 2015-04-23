module JsonApiClient
  module Query
    class Builder

      attr_reader :klass

      def initialize(klass)
        @klass = klass
        @pagination_params = {}
        @base_params = {}
        @includes = []
      end

      def where(conditions = {})
        @base_params.merge!(conditions)
        self
      end

      def order(*args)
        self
      end

      def includes(*tables)
        @includes += parse_related_links(*tables)
        self
      end

      def paginate(conditions = {})
        @pagination_params.merge!(conditions.slice(:page, :per_page))
        self
      end

      def page(number)
        @pagination_params[:page] = number
        self
      end

      def first
        paginate(page: 1, per_page: 1).to_a.first
      end

      def build
        klass.new(params)
      end

      def params
        @base_params.merge(@pagination_params).merge(includes_params)
      end

      def to_a
        @to_a ||= klass.find(params)
      end
      alias all to_a

      def method_missing(method_name, *args, &block)
        to_a.send(method_name, *args, &block)
      end

      private

      def includes_params
        {include: @includes.join(",")}
      end

      def parse_related_links(*tables)
        tables.map do |table|
          case table
          when Hash
            table.map do |k, v|
              parse_related_links(*v).map do |sub|
                "#{k}.#{sub}"
              end
            end
          when Array
            table.map do
              parse_related_links(*table)
            end
          else
            table
          end
        end.flatten
      end

    end
  end
end