module Rswag
  module Specs
    module ExampleGroupHelpers

      def path(template, &block)
        api_metadata = { path_item: { template: template } }
        describe(template, api_metadata, &block)
      end

      [ :get, :post, :patch, :put, :delete, :head ].each do |verb|
        define_method(verb) do |summary, &block|
          api_metadata = { operation: { verb: verb, summary: summary } }
          describe(verb, api_metadata, &block)
        end
      end

      [ :operationId, :deprecated, :security ].each do |attr_name|
        define_method(attr_name) do |value|
          metadata[:operation][attr_name] = value
        end
      end

      # NOTE: 'description' requires special treatment because ExampleGroup already
      # defines a method with that name. Provide an override that supports the existing
      # functionality while also setting the appropriate metadata if applicable
      def description(value=nil)
        return super() if value.nil?
        metadata[:operation][:description] = value
      end

      # These are array properties - note the splat operator
      [ :tags, :consumes, :produces, :schemes ].each do |attr_name|
        define_method(attr_name) do |*value|
          metadata[:operation][attr_name] = value
        end
      end

      def parameter(attributes)
        attributes[:required] = true if attributes[:in].to_sym == :path

        if metadata.has_key?(:operation)
          metadata[:operation][:parameters] ||= []
          metadata[:operation][:parameters] << attributes
        else
          metadata[:path_item][:parameters] ||= []
          metadata[:path_item][:parameters] << attributes
        end
      end

      def response(code, description, &block)
        api_metadata = { response: { code: code, description: description } }
        context(description, api_metadata, &block)
      end

      def schema(value)
        metadata[:response][:schema] = value
      end

      def header(name, attributes)
        metadata[:response][:headers] ||= {}
        metadata[:response][:headers][name] = attributes
      end

      # NOTE: Similar to 'description', 'examples' need to handle the case when
      # being invoked with no params to avoid overriding 'examples' method of
      # rspec-core ExampleGroup
      def examples(example = nil)
        return super() if example.nil?
        metadata[:response][:examples] = example
      end

      def run_test!
        # NOTE: rspec 2.x support
        if RSPEC_VERSION < 3
          before do
            submit_request(example.metadata)
          end

          it "returns a #{metadata[:response][:code]} response" do
            assert_response_matches_metadata(example.metadata)
          end
        else
          before do |example|
            submit_request(example.metadata)
          end

          it "returns a #{metadata[:response][:code]} response" do |example|
            assert_response_matches_metadata(example.metadata)
          end
        end
      end

      def run_request

        before do |example|
          code = example.metadata[:response][:code]
          status = code.to_s.start_with?('2') ? 'success' : 'failure'
          data = self.respond_to?(:data) ? self.data : []
          message = self.respond_to?(:message) ? self.message : ''
          example.metadata[:response][:schema] = Rswag::Specs::SwaggerSchemaLoader.convert(code, status, data, message)
          submit_request(example.metadata)
        end

      end
    end

    module SwaggerSchemaLoader

      def self.convert(code, status, data, message)
        {type: :object,
         properties: {
             code: {type: :integer},
             status: {type: :string},
             data: {
                 type: :array,
                 items: format_items(data)
             },
             message: {type: :string}
         },
         example: {
             code: code,
             status: status,
             data: data,
             message: message,
         },
         required: %w(code, status, data, message)}
      end

      private

      def self.format_items(data)
        data.map do |item|
          {
              type: :object,
              properties: self.format_properties(item),
              example: item
          }
        end
      end

      def self.format_properties(item)
        props = {}
        item.each do |k, v|
          props[k.to_sym] = {type: self.format_types(v)}
        end
        props
      end

      def self.format_types(data)
        case data
          when Fixnum
            :integer
          else
            :string
        end
      end

    end

  end
end
