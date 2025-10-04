# frozen_string_literal: true

require_relative '../mode'

module Instructor
  # Anthropic-specific mode configuration and management
  module Anthropic
    # Sets the current mode for Anthropic API interactions
    #
    # @param mode [Symbol] The mode to use (from Instructor::Mode constants)
    # @return [Symbol] The mode that was set
    def self.mode=(mode)
      @mode = mode
    end

    # Gets the current mode for Anthropic API interactions
    #
    # @return [Symbol] The current mode, defaults to ANTHROPIC_TOOLS
    def self.mode
      @mode ||= Instructor::Mode::ANTHROPIC_TOOLS
    end
  end
end
