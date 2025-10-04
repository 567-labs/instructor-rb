# frozen_string_literal: true

module Instructor
  # Mode module for patching LLM API clients.
  #
  # Each mode determines how the library formats and structures requests
  # to different provider APIs and how it processes their responses.
  #
  # @example Using OpenAI tools mode
  #   client = Instructor.from_openai(openai_client, mode: Instructor::Mode::TOOLS)
  #
  # @example Using Anthropic tools mode
  #   client = Instructor.from_anthropic(anthropic_client, mode: Instructor::Mode::ANTHROPIC_TOOLS)
  module Mode
    # OpenAI Modes

    # Deprecated: Use TOOLS instead
    # @deprecated Use {TOOLS} instead
    FUNCTIONS = :function_call

    # Parallel tool calling mode for OpenAI
    PARALLEL_TOOLS = :parallel_tool_call

    # Standard tool calling mode for OpenAI (recommended)
    TOOLS = :tool_call

    # Strict mode for OpenAI tools with enhanced validation
    TOOLS_STRICT = :tools_strict

    # JSON mode for OpenAI
    JSON = :json_mode

    # JSON schema mode for OpenAI
    JSON_SCHEMA = :json_schema_mode

    # Markdown JSON mode for OpenAI
    MD_JSON = :markdown_json_mode

    # Anthropic Modes

    # Tool calling mode for Anthropic Claude models
    ANTHROPIC_TOOLS = :anthropic_tools

    # JSON mode for Anthropic Claude models
    ANTHROPIC_JSON = :anthropic_json

    # Parallel tool calling mode for Anthropic
    ANTHROPIC_PARALLEL_TOOLS = :anthropic_parallel_tools

    # Reasoning tools mode for Anthropic (extended thinking)
    ANTHROPIC_REASONING_TOOLS = :anthropic_reasoning_tools

    # Track if deprecation warning has been shown
    @functions_deprecation_shown = false

    class << self
      # Returns a set of all tool-based modes.
      #
      # Tool modes use function/tool calling APIs to structure outputs.
      # These modes are recommended for complex, nested data structures.
      #
      # @return [Set<Symbol>] Set of tool mode symbols
      def tool_modes
        Set[
          FUNCTIONS,
          PARALLEL_TOOLS,
          TOOLS,
          TOOLS_STRICT,
          ANTHROPIC_TOOLS,
          ANTHROPIC_REASONING_TOOLS,
          ANTHROPIC_PARALLEL_TOOLS
        ]
      end

      # Returns a set of all JSON-based modes.
      #
      # JSON modes use JSON output formatting to structure responses.
      # These modes are simpler and work with more models.
      #
      # @return [Set<Symbol>] Set of JSON mode symbols
      def json_modes
        Set[
          JSON,
          MD_JSON,
          JSON_SCHEMA,
          ANTHROPIC_JSON
        ]
      end

      # Checks if the given mode is a tool-based mode.
      #
      # @param mode [Symbol] The mode to check
      # @return [Boolean] true if mode is tool-based
      def tool_mode?(mode)
        tool_modes.include?(mode)
      end

      # Checks if the given mode is a JSON-based mode.
      #
      # @param mode [Symbol] The mode to check
      # @return [Boolean] true if mode is JSON-based
      def json_mode?(mode)
        json_modes.include?(mode)
      end

      # Warn about FUNCTIONS mode deprecation.
      #
      # Shows the warning only once per session to avoid spamming logs.
      #
      # @return [void]
      def warn_mode_functions_deprecation
        return if @functions_deprecation_shown

        warn 'DEPRECATION WARNING: The FUNCTIONS mode is deprecated and will be removed in future versions. ' \
             'Please use TOOLS mode instead.'
        @functions_deprecation_shown = true
      end

      # Validates that a mode is supported.
      #
      # @param mode [Symbol] The mode to validate
      # @raise [ArgumentError] if mode is not supported
      # @return [void]
      def validate_mode!(mode)
        all_modes = tool_modes + json_modes
        return if all_modes.include?(mode)

        raise ArgumentError, "Unsupported mode: #{mode}. Supported modes: #{all_modes.to_a.join(', ')}"
      end
    end
  end
end
