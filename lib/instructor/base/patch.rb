# frozen_string_literal: true

module Instructor
  module Base
    module Patch
      # Generates the function name for the API request.
      # You can customize the function name for the LLM by adding a `title` key to the schema.
      # Example:
      # ```ruby
      # class User
      #  include EasyTalk::Model
      #  define_schema do
      #    title 'User'
      #    property :name, String
      #    property :age, Integer
      #  end
      # end
      #  ```
      #  The function name will be `User`.
      #  If the `title` key is not present, the function name will be a modified version of the model's name.
      #  @param model [Class] The response model class.
      #  @return [String] The generated function name.
      def generate_function_name(model)
        model_name = model.json_schema.fetch('title', model.name)
        model_name.gsub('::', '_').gsub(/[^a-zA-Z0-9_]/, '').downcase
      end

      # Generates the description for the function.
      # You can customize the instructions for the LLM by adding an `instructions` class method to the response model.
      # Example:
      # ```ruby
      # class User
      #   include EasyTalk::Model
      #   def self.instructions
      #     'Extract the user name and age from the response'
      #   end
      #
      #   define_schema do ...
      #  end
      #  ```
      #
      # @param model [Class] The response model class.
      # @return [String] The generated description.
      def generate_description(model)
        if model.respond_to?(:instructions)
          raise Instructor::Error, 'The instructions must be a string' unless model.instructions.is_a?(String)

          model.instructions
        else
          "Correctly extracted `#{model.name}` with all the required parameters with correct types"
        end
      end

      private

      # Executes a block of code with retries in case of specific exceptions.
      #
      # @param max_retries [Integer] The maximum number of retries.
      # @param exceptions [Array<Class>] The exceptions to catch and retry.
      # @yield The block of code to execute.
      def with_retries(max_retries, exceptions, &block)
        attempts = 0
        begin
          block.call
        rescue *exceptions
          attempts += 1
          retry if attempts < max_retries
          raise
        end
      end

      # Prepares the parameters for the chat request.
      #
      # @param parameters [Hash] The original parameters.
      # @param validation_context [Hash] The validation context for the parameters.
      # @param function [Hash] The function details.
      # @return [Hash] The prepared parameters.
      def prepare_parameters(parameters, validation_context, function)
        # parameters # fetch the parameters's max_token or set it to 1024
        parameters = apply_validation_context(parameters, validation_context)
        parameters.merge(tools: [function])
      end

      # Processes multiple responses from the API.
      #
      # @param parsed_response [Array<Hash>] The parsed API responses.
      # @param model [Class] The response model class.
      # @return [Array<Object>] The processed responses.
      def process_multiple_responses(parsed_response, model)
        parsed_response.map do |response|
          instance = model.new(response)
          instance.valid? ? instance : raise(Instructor::ValidationError)
        end
      end

      # Processes a single response from the API.
      #
      # @param parsed_response [Hash] The parsed API response.
      # @param model [Class] The response model class.
      # @return [Object] The processed response.
      def process_single_response(parsed_response, model)
        instance = model.new(parsed_response)
        instance.valid? ? instance : raise(Instructor::ValidationError)
      end

      # Determines the response model based on the provided value.
      #
      # @param response_model [Class] The response model class or typed array.
      # @return [Class] The determined response model class.
      def determine_model(response_model)
        if response_model.is_a?(T::Types::TypedArray)
          @iterable = true
          response_model.type.raw_type
        else
          @iterable = false
          response_model
        end
      end

      # Applies the validation context to the parameters.
      #
      # @param parameters [Hash] The original parameters.
      # @param validation_context [Hash] The validation context.
      # @return [Hash] The parameters with applied validation context.
      def apply_validation_context(parameters, validation_context)
        return parameters unless validation_context.is_a?(Hash)

        Array[validation_context].each_with_index do |message, index|
          parameters[:messages][index][:content] = parameters[:messages][index][:content] % message
        end

        parameters
      end

      # Checks if the response is iterable.
      #
      # @return [Boolean] `true` if the response is iterable, `false` otherwise.
      def iterable?
        @iterable
      end
    end
  end
end
