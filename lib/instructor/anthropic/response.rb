# frozen_string_literal: true

module Instructor
  module Anthropic
    # The Response class represents the response received from the Anthropic API.
    # It takes the raw response and provides convenience methods to access the content blocks,
    # tool calls, and parsed arguments.
    class Response
      # Initializes a new instance of the Response class.
      #
      # @param response [Object] The response received from the Anthropic SDK.
      def initialize(response)
        @response = response
      end

      # Parses the function response(s) and returns the parsed arguments.
      #
      # @return [Array, Hash] The parsed arguments.
      def parse
        if single_response?
          arguments.first
        else
          arguments
        end
      end

      private

      def content
        # Handle both hash-like and object-like responses
        if @response.respond_to?(:content)
          @response.content || []
        elsif @response.is_a?(Hash) && @response['content']
          @response['content']
        else
          []
        end
      end

      def tool_calls
        # Filter content blocks for tool_use type
        # Handle both hash-like and object-like blocks
        content.select do |block| 
          (block.respond_to?(:type) && block.type == 'tool_use') || 
          (block.is_a?(Hash) && block['type'] == 'tool_use')
        end
      end

      def single_response?
        tool_calls.size == 1
      end

      def arguments
        tool_calls.map do |tc|
          # Handle both hash-like and object-like inputs
          if tc.respond_to?(:input)
            tc.input
          elsif tc.is_a?(Hash) && tc['input']
            tc['input']
          else
            {}
          end
        end
      end
    end
  end
end
