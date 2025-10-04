# frozen_string_literal: true

require 'spec_helper'
require 'instructor/openai/mode'

RSpec.describe Instructor::OpenAI do
  # Reset the mode after each test to avoid test pollution
  after do
    described_class.mode = nil
  end

  describe '.mode and .mode=' do
    it 'allows setting and getting the mode' do
      described_class.mode = :test_mode
      expect(described_class.mode).to eq(:test_mode)
    end

    it 'returns TOOLS_STRICT when mode is not set' do
      expect(described_class.mode).to eq(Instructor::Mode::TOOLS_STRICT)
    end

    it 'accepts Instructor::Mode constants' do
      described_class.mode = Instructor::Mode::TOOLS
      expect(described_class.mode).to eq(Instructor::Mode::TOOLS)
    end

    it 'accepts Instructor::Mode JSON modes' do
      described_class.mode = Instructor::Mode::JSON
      expect(described_class.mode).to eq(Instructor::Mode::JSON)
    end
  end
end

RSpec.describe Instructor::OpenAI::Mode do
  # Reset the mode after each test to avoid test pollution
  after do
    Instructor::OpenAI.mode = nil
  end

  describe 'deprecated constants' do
    it 'defines STRUCTURED_OUTPUT constant for backward compatibility' do
      expect(described_class::STRUCTURED_OUTPUT).to eq(:structured_output)
    end

    it 'defines FUNCTION_CALLING constant for backward compatibility' do
      expect(described_class::FUNCTION_CALLING).to eq(:function_calling)
    end
  end

  describe '.structured_output? (deprecated)' do
    it 'returns true when mode is set to STRUCTURED_OUTPUT' do
      Instructor::OpenAI.mode = Instructor::OpenAI::Mode::STRUCTURED_OUTPUT
      expect { expect(described_class.structured_output?).to be true }
        .to output(/DEPRECATION WARNING/i).to_stderr
    end

    it 'returns false when mode is set to something else' do
      Instructor::OpenAI.mode = Instructor::OpenAI::Mode::FUNCTION_CALLING
      expect { expect(described_class.structured_output?).to be false }
        .to output(/DEPRECATION WARNING/i).to_stderr
    end

    it 'warns about deprecation' do
      expect { described_class.structured_output? }
        .to output(/DEPRECATION WARNING.*TOOLS_STRICT/i).to_stderr
    end
  end

  describe '.function_calling? (deprecated)' do
    it 'returns true when mode is set to FUNCTION_CALLING' do
      Instructor::OpenAI.mode = Instructor::OpenAI::Mode::FUNCTION_CALLING
      expect { expect(described_class.function_calling?).to be true }
        .to output(/DEPRECATION WARNING/i).to_stderr
    end

    it 'returns false when mode is set to something else' do
      Instructor::OpenAI.mode = Instructor::OpenAI::Mode::STRUCTURED_OUTPUT
      expect { expect(described_class.function_calling?).to be false }
        .to output(/DEPRECATION WARNING/i).to_stderr
    end

    it 'warns about deprecation' do
      expect { described_class.function_calling? }
        .to output(/DEPRECATION WARNING.*TOOLS/i).to_stderr
    end
  end
end
