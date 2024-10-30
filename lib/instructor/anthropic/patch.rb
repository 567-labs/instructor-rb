# frozen_string_literal: true

require 'anthropic'
require 'instructor/base/patch'

# The Instructor module provides functionality for interacting with Anthropic's messages API.
module Instructor
  module Anthropic
    # The `Patch` module provides methods for patching and modifying the Anthropic client behavior.
    module Patch
      include Instructor::Base::Patch

      # Sends a message request to the API and processes the response.
      #
      # @param parameters [Hash] The parameters for the chat request as expected by the OpenAI client.
      # @param response_model [Class] The response model class.
      # @param max_retries [Integer] The maximum number of retries. Default is 0.
      # @param validation_context [Hash] The validation context for the parameters. Optional.
      # @return [Object] The processed response.
      def messages(parameters:, response_model: nil, max_retries: 0, validation_context: nil)
        with_retries(max_retries, [JSON::ParserError, Instructor::ValidationError, Faraday::ParsingError]) do
          model = determine_model(response_model)
          function = build_function(model)
          parameters[:max_tokens] = 1024 unless parameters.key?(:max_tokens)
          parameters = prepare_parameters(parameters, validation_context, function)
          parameters.merge!(build_tool_choice(function))
          response = json_post(path: '/messages', parameters:)
          process_response(response, model)
        end
      end

      # Processes the API response.
      #
      # @param response [Hash] The API response.
      # @param model [Class] The response model class.
      # @return [Object] The processed response.
      def process_response(response, model)
        parsed_response = Response.new(response).parse
        iterable? ? process_multiple_responses(parsed_response, model) : process_single_response(parsed_response, model)
      end

      # Builds the tool choice configuration for the API request.
      #
      # @param function [Hash] The function details.
      # @return [Hash] The tool choice configuration.

      def build_tool_choice(function)
        {
          tool_choice: {
            type: 'tool',
            name: function[:name]
          }
        }
      end

      # Builds the function details for the API request.
      #
      # @param model [Class] The response model class.
      # @return [Hash] The function details.
      def build_function(model)
        {
          name: generate_function_name(model),
          description: generate_description(model),
          input_schema: model.json_schema
        }
      end
    end
  end
end
