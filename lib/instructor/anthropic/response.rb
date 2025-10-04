# frozen_string_literal: true

module Instructor
  module Anthropic
    module Response
      # Factory method to create the appropriate response type based on the mode
      #
      # @param response [Hash] The response received from the Anthropic API
      # @return [ToolResponse, JsonResponse] The appropriate response object
      def self.create(response)
        current_mode = Instructor::Anthropic.mode

        if tool_mode?(current_mode)
          ToolResponse.new(response)
        elsif json_mode?(current_mode)
          JsonResponse.new(response)
        else
          raise ArgumentError, "Invalid Anthropic mode: #{current_mode}"
        end
      end

      # Checks if the current mode is a tool-based mode
      #
      # @param mode [Symbol] The mode to check
      # @return [Boolean] true if mode uses tools
      def self.tool_mode?(mode)
        Instructor::Mode.tool_mode?(mode) && mode.to_s.start_with?('anthropic')
      end

      # Checks if the current mode is a JSON-based mode
      #
      # @param mode [Symbol] The mode to check
      # @return [Boolean] true if mode uses JSON prompting
      def self.json_mode?(mode)
        mode == Instructor::Mode::ANTHROPIC_JSON
      end

      # Base class for Anthropic API responses with common error handling
      class BaseResponse
        def initialize(response)
          @response = response
        end

        def error?
          @response['type'] == 'error'
        end

        def error_message
          "#{@response.dig('error', 'type')} - #{@response.dig('error', 'message')}"
        end
      end

      # Tool-based response handler for ANTHROPIC_TOOLS, ANTHROPIC_REASONING_TOOLS, and ANTHROPIC_PARALLEL_TOOLS modes
      class ToolResponse < BaseResponse
        # Parses the tool response(s) and returns the parsed arguments.
        #
        # @return [Array, Hash] The parsed arguments.
        # @raise [StandardError] if the api response contains an error.
        def parse
          raise StandardError, error_message if error?

          if single_response?
            arguments.first
          else
            arguments
          end
        end

        private

        def content
          @response['content']
        end

        def tool_calls
          content.is_a?(Array) && content.select { |c| c['type'] == 'tool_use' }
        end

        def single_response?
          tool_calls&.size == 1
        end

        def arguments
          tool_calls.map { |tc| tc['input'] }
        end
      end

      # JSON-based response handler for ANTHROPIC_JSON mode
      class JsonResponse < BaseResponse
        # Parses the JSON content from the response.
        #
        # @return [Hash] The parsed JSON data.
        # @raise [StandardError] if the api response contains an error.
        def parse
          raise StandardError, error_message if error?

          # Extract text content from response
          text_content = extract_text_content

          # Parse JSON from the text
          JSON.parse(text_content)
        rescue JSON::ParserError => e
          raise StandardError, "Failed to parse JSON response: #{e.message}"
        end

        private

        def extract_text_content
          content = @response['content']

          if content.is_a?(Array)
            # Find first text content block
            text_block = content.find { |c| c['type'] == 'text' }
            text_block&.dig('text') || ''
          elsif content.is_a?(String)
            content
          else
            ''
          end
        end
      end
    end
  end
end
