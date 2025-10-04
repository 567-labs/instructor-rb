# frozen_string_literal: true

require 'spec_helper'
require 'instructor/anthropic/mode'

RSpec.describe Instructor::Anthropic do
  # Reset the mode after each test to avoid test pollution
  after do
    described_class.mode = nil
  end

  describe '.mode and .mode=' do
    it 'allows setting and getting the mode' do
      described_class.mode = :test_mode
      expect(described_class.mode).to eq(:test_mode)
    end

    it 'returns ANTHROPIC_TOOLS when mode is not set' do
      expect(described_class.mode).to eq(Instructor::Mode::ANTHROPIC_TOOLS)
    end

    it 'accepts Instructor::Mode::ANTHROPIC_TOOLS constant' do
      described_class.mode = Instructor::Mode::ANTHROPIC_TOOLS
      expect(described_class.mode).to eq(Instructor::Mode::ANTHROPIC_TOOLS)
    end

    it 'accepts Instructor::Mode::ANTHROPIC_JSON constant' do
      described_class.mode = Instructor::Mode::ANTHROPIC_JSON
      expect(described_class.mode).to eq(Instructor::Mode::ANTHROPIC_JSON)
    end

    it 'accepts Instructor::Mode::ANTHROPIC_REASONING_TOOLS constant' do
      described_class.mode = Instructor::Mode::ANTHROPIC_REASONING_TOOLS
      expect(described_class.mode).to eq(Instructor::Mode::ANTHROPIC_REASONING_TOOLS)
    end

    it 'accepts Instructor::Mode::ANTHROPIC_PARALLEL_TOOLS constant' do
      described_class.mode = Instructor::Mode::ANTHROPIC_PARALLEL_TOOLS
      expect(described_class.mode).to eq(Instructor::Mode::ANTHROPIC_PARALLEL_TOOLS)
    end
  end
end
