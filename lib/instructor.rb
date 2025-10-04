# frozen_string_literal: true

require 'openai'
require 'anthropic'
require 'easy_talk'
require 'active_support/all'
require_relative 'instructor/version'
require_relative 'instructor/mode'
require_relative 'instructor/openai/patch'
require_relative 'instructor/openai/response'
require_relative 'instructor/openai/mode'
require_relative 'instructor/anthropic/mode'
require_relative 'instructor/anthropic/patch'
require_relative 'instructor/anthropic/response'

# Instructor makes it easy to reliably get structured data like JSON from Large Language Models (LLMs)
# like GPT-3.5, GPT-4, GPT-4-Vision
module Instructor
  class Error < ::StandardError; end

  # The ValidationError class represents an error that occurs during validation.
  class ValidationError < ::StandardError; end

  # Patches the OpenAI client to add the following functionality:
  # - Retries on exceptions
  # - Accepts and validates a response model
  # - Accepts a validation_context argument
  #
  # @param openai_client [OpenAI::Client] The OpenAI client to be patched.
  # @param mode [Symbol] The mode to be used. Default is `Instructor::Mode::TOOLS_STRICT`.
  # @return [OpenAI::Client] The patched OpenAI client.
  # @example Using tools strict mode (default)
  #   client = Instructor.from_openai(openai_client)
  # @example Using standard tools mode
  #   client = Instructor.from_openai(openai_client, mode: Instructor::Mode::TOOLS)
  # @example Using JSON mode
  #   client = Instructor.from_openai(openai_client, mode: Instructor::Mode::JSON)
  def self.from_openai(openai_client, mode: Instructor::Mode::TOOLS_STRICT)
    Instructor::OpenAI.mode = mode
    openai_client.prepend(Instructor::OpenAI::Patch)
  end

  # Patches the Anthropic client to add the following functionality:
  # - Retries on exceptions
  # - Accepts and validates a response model
  # - Accepts a validation_context argument
  # - Supports multiple extraction modes
  #
  # @param anthropic_client [Anthropic::Client] The Anthropic client to be patched.
  # @param mode [Symbol] The mode to be used. Default is `Instructor::Mode::ANTHROPIC_TOOLS`.
  # @return [Anthropic::Client] The patched Anthropic client.
  # @example Using tools mode (default) - forces specific tool use
  #   client = Instructor.from_anthropic(anthropic_client)
  # @example Using JSON mode - prompt-based extraction
  #   client = Instructor.from_anthropic(anthropic_client, mode: Instructor::Mode::ANTHROPIC_JSON)
  # @example Using reasoning tools mode - allows Claude to reason
  #   client = Instructor.from_anthropic(anthropic_client, mode: Instructor::Mode::ANTHROPIC_REASONING_TOOLS)
  # @example Using parallel tools mode - multiple tools
  #   client = Instructor.from_anthropic(anthropic_client, mode: Instructor::Mode::ANTHROPIC_PARALLEL_TOOLS)
  def self.from_anthropic(anthropic_client, mode: Instructor::Mode::ANTHROPIC_TOOLS)
    Instructor::Anthropic.mode = mode
    anthropic_client.prepend(Instructor::Anthropic::Patch)
  end
end
