# frozen_string_literal: true

require 'anthropic'
require 'instructor/base/patch'

# The Instructor module provides functionality for interacting with Anthropic's messages API.
module Instructor
  module Anthropic
    # The `Patch` module provides methods for patching and modifying the Anthropic client behavior.
    module Patch
      include Instructor::Base::Patch

      # Sends a chat request to the API and processes the response.
      #
      # @param parameters [Hash] The parameters for the chat request as expected by the Anthropic client.
      # @param response_model [Class] The response model class.
      # @param max_retries [Integer] The maximum number of retries. Default is 0.
      # @param validation_context [Hash] The validation context for the parameters. Optional.
      # @return [Object] The processed response.
      def messages(parameters:, response_model: nil, max_retries: 0, validation_context: nil)
        return super(parameters:) if response_model.nil?

        model = determine_model(response_model)
        current_mode = Instructor::Anthropic.mode

        set_max_tokens(parameters)

        # Mode-specific parameter preparation
        if tool_mode?(current_mode)
          function = build_function(model)
          parameters = prepare_tool_parameters(parameters, validation_context, function, current_mode)
          set_extra_headers
        elsif json_mode?(current_mode)
          parameters = prepare_json_parameters(parameters, validation_context, model)
        else
          raise ArgumentError, "Invalid Anthropic mode: #{current_mode}"
        end

        response = super(parameters:)
        process_response(response, model)
      end

      private

      # Checks if the current mode is a tool-based mode
      #
      # @param mode [Symbol] The mode to check
      # @return [Boolean] true if mode uses tools
      def tool_mode?(mode)
        Instructor::Mode.tool_mode?(mode) && mode.to_s.start_with?('anthropic')
      end

      # Checks if the current mode is a JSON-based mode
      #
      # @param mode [Symbol] The mode to check
      # @return [Boolean] true if mode uses JSON prompting
      def json_mode?(mode)
        mode == Instructor::Mode::ANTHROPIC_JSON
      end

      def set_max_tokens(parameters)
        parameters[:max_tokens] = 1024 unless parameters.key?(:max_tokens)
      end

      def set_extra_headers
        ::Anthropic.configuration.extra_headers = { 'anthropic-beta' => 'tools-2024-04-04' }
      end

      def function_name(function)
        function[:name]
      end

      # Prepares parameters for tool-based modes
      #
      # @param parameters [Hash] Original parameters
      # @param validation_context [Hash] Validation context
      # @param function [Hash] Function/tool definition
      # @param mode [Symbol] Current mode
      # @return [Hash] Prepared parameters with tools and tool_choice
      def prepare_tool_parameters(parameters, validation_context, function, mode)
        parameters = apply_validation_context(parameters, validation_context)
        parameters = parameters.merge(tools: [function])

        tool_choice = resolve_tool_choice(function_name(function), mode)
        parameters.merge!(tool_choice:) if tool_choice

        parameters
      end

      # Prepares parameters for JSON mode (prompt-based)
      #
      # @param parameters [Hash] Original parameters
      # @param validation_context [Hash] Validation context
      # @param model [Class] Response model class
      # @return [Hash] Prepared parameters with JSON schema in system prompt
      def prepare_json_parameters(parameters, validation_context, model)
        parameters = apply_validation_context(parameters, validation_context)

        # Generate JSON schema prompt
        json_schema_message = <<~PROMPT.strip
          As a genius expert, your task is to understand the content and provide
          the parsed objects in json that match the following json_schema:

          #{JSON.pretty_generate(model.json_schema)}

          Make sure to return an instance of the JSON, not the schema itself.
        PROMPT

        # Inject into system messages
        system_messages = build_system_messages(parameters[:system], json_schema_message)
        parameters.merge(system: system_messages)
      end

      # Builds system messages array combining existing and schema messages
      #
      # @param existing_system [String, Array, nil] Existing system messages
      # @param schema_message [String] JSON schema instruction message
      # @return [Array<Hash>] Array of system message hashes
      def build_system_messages(existing_system, schema_message)
        messages = []

        # Add existing system messages
        if existing_system.is_a?(String)
          messages << { type: 'text', text: existing_system }
        elsif existing_system.is_a?(Array)
          messages.concat(existing_system)
        end

        # Add schema message
        messages << { type: 'text', text: schema_message }

        messages
      end

      # Resolves tool_choice based on mode
      #
      # @param function_name [String] Name of the function/tool
      # @param mode [Symbol] Current mode
      # @return [Hash, nil] Tool choice configuration or nil
      def resolve_tool_choice(function_name, mode)
        case mode
        when Instructor::Mode::ANTHROPIC_TOOLS
          # Force specific tool use
          { type: 'tool', name: function_name }
        when Instructor::Mode::ANTHROPIC_REASONING_TOOLS, Instructor::Mode::ANTHROPIC_PARALLEL_TOOLS
          # Allow Claude to reason/choose
          { type: 'auto' }
        end
      end

      # Processes the API response.
      #
      # @param response [Hash] The API response.
      # @param model [Class] The response model class.
      # @return [Object] The processed response.
      def process_response(response, model)
        parsed_response = Response.create(response).parse
        iterable? ? process_multiple_responses(parsed_response, model) : process_single_response(parsed_response, model)
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
