# frozen_string_literal: true

require_relative '../mode'

module Instructor
  # This module defines constants related to different modes of operation for the OpenAI api.
  # It provides options for tool behavior, function types, and JSON modes.
  # Currently supported modes are:
  # - tools: select between function, auto, required, and none.
  module OpenAI
    def self.mode=(mode)
      @mode = mode
    end

    def self.mode
      @mode ||= Instructor::Mode::TOOLS_STRICT
    end

    # @deprecated Use {Instructor::Mode} instead. This module will be removed in a future version.
    module Mode
      # @deprecated Use {Instructor::Mode::TOOLS_STRICT} instead
      STRUCTURED_OUTPUT = :structured_output

      # @deprecated Use {Instructor::Mode::TOOLS} instead
      FUNCTION_CALLING = :function_calling

      # @deprecated Use {Instructor::Mode.tool_mode?} instead
      def self.structured_output?
        warn 'DEPRECATION WARNING: Instructor::OpenAI::Mode.structured_output? is deprecated. ' \
             'Use Instructor::Mode::TOOLS_STRICT instead.'
        Instructor::OpenAI.mode == STRUCTURED_OUTPUT
      end

      # @deprecated Use {Instructor::Mode.tool_mode?} instead
      def self.function_calling?
        warn 'DEPRECATION WARNING: Instructor::OpenAI::Mode.function_calling? is deprecated. ' \
             'Use Instructor::Mode::TOOLS instead.'
        Instructor::OpenAI.mode == FUNCTION_CALLING
      end
    end
  end
end
