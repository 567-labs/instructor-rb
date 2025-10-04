# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Instructor::Anthropic::Response do
  after { Instructor::Anthropic.mode = nil }

  describe '.create' do
    let(:response) { { 'content' => [] } }

    context 'when in ANTHROPIC_TOOLS mode' do
      before { Instructor::Anthropic.mode = Instructor::Mode::ANTHROPIC_TOOLS }

      it 'returns a ToolResponse instance' do
        expect(described_class.create(response)).to be_a(described_class::ToolResponse)
      end
    end

    context 'when in ANTHROPIC_REASONING_TOOLS mode' do
      before { Instructor::Anthropic.mode = Instructor::Mode::ANTHROPIC_REASONING_TOOLS }

      it 'returns a ToolResponse instance' do
        expect(described_class.create(response)).to be_a(described_class::ToolResponse)
      end
    end

    context 'when in ANTHROPIC_PARALLEL_TOOLS mode' do
      before { Instructor::Anthropic.mode = Instructor::Mode::ANTHROPIC_PARALLEL_TOOLS }

      it 'returns a ToolResponse instance' do
        expect(described_class.create(response)).to be_a(described_class::ToolResponse)
      end
    end

    context 'when in ANTHROPIC_JSON mode' do
      before { Instructor::Anthropic.mode = Instructor::Mode::ANTHROPIC_JSON }

      it 'returns a JsonResponse instance' do
        expect(described_class.create(response)).to be_a(described_class::JsonResponse)
      end
    end
  end

  describe Instructor::Anthropic::Response::ToolResponse do
    subject(:response_object) { described_class.new(response) }

    let(:response) do
      {
        'id' => 'msg_123',
        'type' => 'message',
        'role' => 'assistant',
        'content' => [
          {
            'type' => 'tool_use',
            'id' => 'toolu_456',
            'name' => 'User',
            'input' => { 'name' => 'Jason', 'age' => 25 }
          }
        ]
      }
    end

    describe '#parse' do
      it 'returns the tool input for single response' do
        expect(response_object.parse).to eq({ 'name' => 'Jason', 'age' => 25 })
      end

      context 'with multiple tool uses' do
        let(:response) do
          {
            'id' => 'msg_123',
            'type' => 'message',
            'content' => [
              {
                'type' => 'tool_use',
                'name' => 'User',
                'input' => { 'name' => 'Jason', 'age' => 25 }
              },
              {
                'type' => 'tool_use',
                'name' => 'User',
                'input' => { 'name' => 'Alice', 'age' => 30 }
              }
            ]
          }
        end

        it 'returns an array of tool inputs' do
          expected = [
            { 'name' => 'Jason', 'age' => 25 },
            { 'name' => 'Alice', 'age' => 30 }
          ]
          expect(response_object.parse).to eq(expected)
        end
      end

      context 'with error response' do
        let(:response) do
          {
            'type' => 'error',
            'error' => {
              'type' => 'invalid_request_error',
              'message' => 'Invalid request'
            }
          }
        end

        it 'raises an error with the error message' do
          expect { response_object.parse }.to raise_error(StandardError, /invalid_request_error.*Invalid request/)
        end
      end
    end
  end

  describe Instructor::Anthropic::Response::JsonResponse do
    subject(:response_object) { described_class.new(response) }

    describe '#parse' do
      context 'with text content containing JSON' do
        let(:response) do
          {
            'id' => 'msg_123',
            'type' => 'message',
            'content' => [
              {
                'type' => 'text',
                'text' => '{"name": "Jason", "age": 25}'
              }
            ]
          }
        end

        it 'parses the JSON from text content' do
          expect(response_object.parse).to eq({ 'name' => 'Jason', 'age' => 25 })
        end
      end

      context 'with string content' do
        let(:response) do
          {
            'id' => 'msg_123',
            'type' => 'message',
            'content' => '{"name": "Jason", "age": 25}'
          }
        end

        it 'parses the JSON from string content' do
          expect(response_object.parse).to eq({ 'name' => 'Jason', 'age' => 25 })
        end
      end

      context 'with invalid JSON' do
        let(:response) do
          {
            'id' => 'msg_123',
            'type' => 'message',
            'content' => [
              {
                'type' => 'text',
                'text' => 'not valid json'
              }
            ]
          }
        end

        it 'raises an error' do
          expect { response_object.parse }.to raise_error(StandardError, /Failed to parse JSON/)
        end
      end

      context 'with error response' do
        let(:response) do
          {
            'type' => 'error',
            'error' => {
              'type' => 'invalid_request_error',
              'message' => 'Invalid request'
            }
          }
        end

        it 'raises an error with the error message' do
          expect { response_object.parse }.to raise_error(StandardError, /invalid_request_error.*Invalid request/)
        end
      end
    end
  end
end
