# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Instructor::OpenAI::Response do
  describe '.create' do
    let(:response) { { 'choices' => [] } }

    after { Instructor::OpenAI.mode = nil }

    context 'when in structured output mode' do
      before { Instructor::OpenAI.mode = Instructor::Mode::TOOLS_STRICT }

      it 'returns a StructuredResponse instance' do
        expect(described_class.create(response)).to be_a(described_class::StructuredResponse)
      end
    end

    context 'when in function calling mode' do
      before { Instructor::OpenAI.mode = Instructor::Mode::TOOLS }

      it 'returns a ToolResponse instance' do
        expect(described_class.create(response)).to be_a(described_class::ToolResponse)
      end
    end

    context 'when in legacy structured output mode' do
      before { Instructor::OpenAI.mode = :structured_output }

      it 'returns a StructuredResponse instance for backward compatibility' do
        expect(described_class.create(response)).to be_a(described_class::StructuredResponse)
      end
    end

    context 'when in legacy function calling mode' do
      before { Instructor::OpenAI.mode = :function_calling }

      it 'returns a ToolResponse instance for backward compatibility' do
        expect(described_class.create(response)).to be_a(described_class::ToolResponse)
      end
    end
  end

  describe Instructor::OpenAI::Response::BaseResponse do
    subject(:response_object) { described_class.new(response) }

    let(:response) do
      { 'id' => 'chatcmpl-base',
        'object' => 'chat.completion',
        'created' => 1_712_940_147,
        'choices' => [
          { 'index' => 0,
            'message' => {
              'role' => 'assistant',
              'refusal' => 'I cannot assist with that request'
            },
            'finish_reason' => 'stop' }
        ] }
    end

    it 'returns chat completions' do
      expect(response_object.chat_completions).to eq(response['choices'])
    end

    it 'returns refusal message' do
      expect(response_object.refusal).to eq('I cannot assist with that request')
    end

    context 'with empty response' do
      let(:response) { {} }

      it 'handles missing choices gracefully' do
        expect(response_object.chat_completions).to be_nil
      end

      it 'handles missing refusal gracefully' do
        expect(response_object.refusal).to be_nil
      end
    end
  end

  describe Instructor::OpenAI::Response::ToolResponse do
    subject(:response_object) { described_class.new(response) }

    let(:response) do
      { 'id' => 'chatcmpl-9DEGpBfHqcS17uJtx1vxpRMEb4DtK',
        'object' => 'chat.completion',
        'created' => 1_712_940_147,
        'model' => 'gpt-3.5-turbo-0125',
        'choices' => [
          { 'index' => 0,
            'message' =>
          { 'role' => 'assistant',
            'content' => nil,
            'tool_calls' => [
              {
                'id' => 'call_ljjAxRNujNWmDhrlJW2DLprK',
                'type' => 'function',
                'function' => { 'name' => 'User', 'arguments' => '{"name": "Jason", "age": 25}' }
              }
            ] },
            'logprobs' => nil,
            'finish_reason' => 'tool_calls' }
        ],
        'usage' => {
          'prompt_tokens' => 63,
          'completion_tokens' => 32,
          'total_tokens' => 95
        },
        'system_fingerprint' => 'fp_c2295e73ad' }
    end

    it 'returns a chat completion' do
      expect(response_object.chat_completions).to eq(response['choices'])
    end

    it 'returns the tool calls' do
      expect(response_object.tool_calls).to eq(response['choices'][0]['message']['tool_calls'])
    end

    it 'returns the function responses' do
      expect(response_object.function_responses).to eq([response['choices'][0]['message']['tool_calls'][0]['function']])
    end

    it 'returns the function arguments by function name' do
      expect(response_object.by_function_name('User')).to eq('{"name": "Jason", "age": 25}')
    end

    it 'single response' do
      expect(response_object.single_response?).to eq(true)
    end

    it 'parses the response' do
      expect(response_object.parse).to eq('name' => 'Jason', 'age' => 25)
    end

    it 'returns the first function response' do
      expect(response_object.function_response).to eq(response['choices'][0]['message']['tool_calls'][0]['function'])
    end

    context 'with multiple function responses' do
      let(:response) do
        { 'id' => 'chatcmpl-multi',
          'object' => 'chat.completion',
          'created' => 1_712_940_147,
          'choices' => [
            { 'index' => 0,
              'message' => {
                'role' => 'assistant',
                'content' => nil,
                'tool_calls' => [
                  {
                    'id' => 'call_1',
                    'type' => 'function',
                    'function' => { 'name' => 'User1', 'arguments' => '{"name": "Alice", "age": 30}' }
                  },
                  {
                    'id' => 'call_2',
                    'type' => 'function',
                    'function' => { 'name' => 'User2', 'arguments' => '{"name": "Bob", "age": 25}' }
                  }
                ]
              },
              'finish_reason' => 'tool_calls' }
          ] }
      end

      it 'identifies multiple responses' do
        expect(response_object.single_response?).to eq(false)
      end

      it 'returns all function responses' do
        expect(response_object.function_responses.size).to eq(2)
      end

      it 'parses multiple responses correctly' do
        expected_result = [
          { 'name' => 'Alice', 'age' => 30 },
          { 'name' => 'Bob', 'age' => 25 }
        ]
        expect(response_object.parse).to eq(expected_result)
      end

      it 'returns the correct function by name' do
        expect(response_object.by_function_name('User2')).to eq('{"name": "Bob", "age": 25}')
      end
    end

    context 'with invalid JSON in arguments' do
      let(:response) do
        { 'choices' => [
          { 'message' => {
            'tool_calls' => [
              {
                'function' => { 'name' => 'User', 'arguments' => '{invalid json}' }
              }
            ]
          } }
        ] }
      end

      it 'raises a JSON::ParserError when parsing invalid JSON' do
        expect { response_object.parse }.to raise_error(JSON::ParserError)
      end
    end

    context 'with empty response' do
      let(:response) { {} }

      it 'handles missing data gracefully' do
        expect(response_object.tool_calls).to be_nil
        expect(response_object.function_responses).to be_nil
        expect(response_object.function_response).to be_nil
        expect(response_object.single_response?).to eq(false)
      end
    end
  end

  describe Instructor::OpenAI::Response::StructuredResponse do
    subject(:response_object) { described_class.new(response) }

    let(:response) do
      { 'id' => 'chatcmpl-123',
        'object' => 'chat.completion',
        'created' => 1_712_940_147,
        'model' => 'gpt-3.5-turbo-0125',
        'choices' => [
          { 'index' => 0,
            'message' => {
              'role' => 'assistant',
              'content' => '{"name": "Jason", "age": 25}'
            },
            'finish_reason' => 'stop' }
        ] }
    end

    it 'returns chat completions' do
      expect(response_object.chat_completions).to eq(response['choices'])
    end

    it 'returns content' do
      expect(response_object.content).to eq('{"name": "Jason", "age": 25}')
    end

    it 'parses the response' do
      expect(response_object.parse).to eq('name' => 'Jason', 'age' => 25)
    end

    context 'with invalid JSON content' do
      let(:response) do
        { 'choices' => [
          { 'message' => {
            'content' => '{invalid json}'
          } }
        ] }
      end

      it 'returns nil when parsing invalid JSON' do
        expect(response_object.parse).to be_nil
      end
    end

    context 'with empty response' do
      let(:response) { {} }

      it 'handles missing content gracefully' do
        expect(response_object.content).to be_nil
        expect(response_object.parse).to be_nil
      end
    end
  end
end
