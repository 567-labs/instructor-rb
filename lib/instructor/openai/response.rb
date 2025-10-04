# frozen_string_literal: true

module Instructor
  module OpenAI
    module Response
      # Factory method to create the appropriate response type based on the mode
      #
      # @param response [Hash] The response received from the OpenAI API
      # @return [ToolResponse, StructuredResponse] The appropriate response object
      def self.create(response)
        current_mode = Instructor::OpenAI.mode

        if structured_output_mode?(current_mode)
          StructuredResponse.new(response)
        elsif tool_calling_mode?(current_mode)
          ToolResponse.new(response)
        else
          raise ArgumentError, "Invalid mode: #{current_mode}"
        end
      end

      # Checks if the current mode is a structured output mode
      #
      # @param mode [Symbol] The mode to check
      # @return [Boolean] true if mode uses structured output (response_format)
      def self.structured_output_mode?(mode)
        mode == Instructor::Mode::TOOLS_STRICT ||
          mode == Instructor::Mode::JSON_SCHEMA ||
          mode == :structured_output
      end

      # Checks if the current mode is a tool calling mode
      #
      # @param mode [Symbol] The mode to check
      # @return [Boolean] true if mode uses tool calling
      def self.tool_calling_mode?(mode)
        Instructor::Mode.tool_mode?(mode) ||
          mode == :function_calling
      end

      # Base class for OpenAI API responses that contains common functionality
      class BaseResponse
        # Initializes a new instance with the OpenAI API response.
        #
        # @param response [Hash] The response received from the OpenAI API.
        def initialize(response)
          @response = response
        end

        # Returns the chat completions from the response.
        #
        # @return [Array] An array of chat completions.
        def chat_completions
          @response['choices']
        end

        # Returns the refusal from the first chat completion.
        #
        # @return [String, nil] The refusal or nil if not found.
        def refusal
          chat_completions&.dig(0, 'message', 'refusal')
        end
      end

      # The ToolResponse class represents the response received from the OpenAI API
      # when using function calling mode. It takes the raw response and provides
      # convenience methods to access the chat completions, tool calls, function
      # responses, and parsed arguments.
      class ToolResponse < BaseResponse
        # Returns the tool calls from the chat completions.
        #
        # @return [Hash, nil] The tool calls or nil if not found.
        def tool_calls
          chat_completions&.dig(0, 'message', 'tool_calls')
        end

        # Returns the function responses from the tool calls.
        #
        # @return [Array, nil] An array of function responses or nil if not found.
        def function_responses
          tool_calls&.map { |tool_call| tool_call['function'] }
        end

        # Returns the first function response.
        #
        # @return [Hash, nil] The first function response or nil if not found.
        def function_response
          function_responses&.first
        end

        # Checks if there is only a single function response.
        #
        # @return [Boolean] True if there is only a single function response, false otherwise.
        def single_response?
          function_responses&.size == 1
        end

        # Parses the function response(s) and returns the parsed arguments.
        #
        # @return [Array, Hash] The parsed arguments.
        def parse
          if single_response?
            JSON.parse(function_response['arguments'])
          else
            function_responses.map { |res| JSON.parse(res['arguments']) }
          end
        end

        # Returns the arguments of the function with the specified name.
        #
        # @param function_name [String] The name of the function.
        # @return [Hash, nil] The arguments of the function or nil if not found.
        def by_function_name(function_name)
          function_responses&.find { |res| res['name'] == function_name }&.dig('arguments')
        end
      end

      # The StructuredResponse class represents the response received from the OpenAI API
      # when using structured output mode. It takes the raw response and provides
      # convenience methods to access the chat completions and parse the JSON content.
      class StructuredResponse < BaseResponse
        # Returns the content from the first chat completion.
        #
        # @return [String, nil] The content or nil if not found.
        def content
          chat_completions&.dig(0, 'message', 'content')
        end

        # Parses the content as JSON and returns the parsed data.
        #
        # @return [Hash] The parsed JSON data.
        def parse
          JSON.parse(content)
        rescue StandardError
          nil
        end
      end
    end
  end
end
