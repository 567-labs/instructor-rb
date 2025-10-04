# frozen_string_literal: true

require 'spec_helper'
require 'instructor/mode'

RSpec.describe Instructor::Mode do
  describe 'OpenAI mode constants' do
    it 'defines FUNCTIONS constant' do
      expect(described_class::FUNCTIONS).to eq(:function_call)
    end

    it 'defines PARALLEL_TOOLS constant' do
      expect(described_class::PARALLEL_TOOLS).to eq(:parallel_tool_call)
    end

    it 'defines TOOLS constant' do
      expect(described_class::TOOLS).to eq(:tool_call)
    end

    it 'defines TOOLS_STRICT constant' do
      expect(described_class::TOOLS_STRICT).to eq(:tools_strict)
    end

    it 'defines JSON constant' do
      expect(described_class::JSON).to eq(:json_mode)
    end

    it 'defines JSON_SCHEMA constant' do
      expect(described_class::JSON_SCHEMA).to eq(:json_schema_mode)
    end

    it 'defines MD_JSON constant' do
      expect(described_class::MD_JSON).to eq(:markdown_json_mode)
    end
  end

  describe 'Anthropic mode constants' do
    it 'defines ANTHROPIC_TOOLS constant' do
      expect(described_class::ANTHROPIC_TOOLS).to eq(:anthropic_tools)
    end

    it 'defines ANTHROPIC_JSON constant' do
      expect(described_class::ANTHROPIC_JSON).to eq(:anthropic_json)
    end

    it 'defines ANTHROPIC_PARALLEL_TOOLS constant' do
      expect(described_class::ANTHROPIC_PARALLEL_TOOLS).to eq(:anthropic_parallel_tools)
    end

    it 'defines ANTHROPIC_REASONING_TOOLS constant' do
      expect(described_class::ANTHROPIC_REASONING_TOOLS).to eq(:anthropic_reasoning_tools)
    end
  end

  describe '.tool_modes' do
    it 'returns a Set of all tool-based modes' do
      expected_modes = Set[
        :function_call,
        :parallel_tool_call,
        :tool_call,
        :tools_strict,
        :anthropic_tools,
        :anthropic_reasoning_tools,
        :anthropic_parallel_tools
      ]
      expect(described_class.tool_modes).to eq(expected_modes)
    end

    it 'returns a Set object' do
      expect(described_class.tool_modes).to be_a(Set)
    end
  end

  describe '.json_modes' do
    it 'returns a Set of all JSON-based modes' do
      expected_modes = Set[
        :json_mode,
        :markdown_json_mode,
        :json_schema_mode,
        :anthropic_json
      ]
      expect(described_class.json_modes).to eq(expected_modes)
    end

    it 'returns a Set object' do
      expect(described_class.json_modes).to be_a(Set)
    end
  end

  describe '.tool_mode?' do
    it 'returns true for tool-based modes' do
      expect(described_class.tool_mode?(described_class::TOOLS)).to be true
      expect(described_class.tool_mode?(described_class::TOOLS_STRICT)).to be true
      expect(described_class.tool_mode?(described_class::ANTHROPIC_TOOLS)).to be true
    end

    it 'returns false for JSON-based modes' do
      expect(described_class.tool_mode?(described_class::JSON)).to be false
      expect(described_class.tool_mode?(described_class::ANTHROPIC_JSON)).to be false
    end

    it 'returns false for unknown modes' do
      expect(described_class.tool_mode?(:unknown_mode)).to be false
    end
  end

  describe '.json_mode?' do
    it 'returns true for JSON-based modes' do
      expect(described_class.json_mode?(described_class::JSON)).to be true
      expect(described_class.json_mode?(described_class::JSON_SCHEMA)).to be true
      expect(described_class.json_mode?(described_class::ANTHROPIC_JSON)).to be true
    end

    it 'returns false for tool-based modes' do
      expect(described_class.json_mode?(described_class::TOOLS)).to be false
      expect(described_class.json_mode?(described_class::ANTHROPIC_TOOLS)).to be false
    end

    it 'returns false for unknown modes' do
      expect(described_class.json_mode?(:unknown_mode)).to be false
    end
  end

  describe '.warn_mode_functions_deprecation' do
    it 'warns about FUNCTIONS mode deprecation' do
      # Reset the warning flag
      described_class.instance_variable_set(:@functions_deprecation_shown, false)

      expect { described_class.warn_mode_functions_deprecation }
        .to output(/DEPRECATION WARNING.*FUNCTIONS mode is deprecated/i).to_stderr
    end

    it 'only warns once per session' do
      # Reset the warning flag
      described_class.instance_variable_set(:@functions_deprecation_shown, false)

      # First call should warn
      expect { described_class.warn_mode_functions_deprecation }
        .to output(/DEPRECATION WARNING/i).to_stderr

      # Second call should not warn
      expect { described_class.warn_mode_functions_deprecation }
        .not_to output.to_stderr
    end
  end

  describe '.validate_mode!' do
    it 'does not raise error for valid tool modes' do
      expect { described_class.validate_mode!(described_class::TOOLS) }.not_to raise_error
      expect { described_class.validate_mode!(described_class::ANTHROPIC_TOOLS) }.not_to raise_error
    end

    it 'does not raise error for valid JSON modes' do
      expect { described_class.validate_mode!(described_class::JSON) }.not_to raise_error
      expect { described_class.validate_mode!(described_class::ANTHROPIC_JSON) }.not_to raise_error
    end

    it 'raises ArgumentError for unsupported modes' do
      expect { described_class.validate_mode!(:invalid_mode) }
        .to raise_error(ArgumentError, /Unsupported mode: invalid_mode/)
    end

    it 'includes list of supported modes in error message' do
      expect { described_class.validate_mode!(:invalid_mode) }
        .to raise_error(ArgumentError, /Supported modes:/)
    end
  end
end
