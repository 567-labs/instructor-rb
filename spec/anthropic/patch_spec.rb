# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Instructor::Anthropic::Patch do
  subject(:patched_client) { Instructor.from_anthropic(Anthropic::Client) }

  # Reset mode after each test
  after do
    Instructor::Anthropic.mode = nil
  end

  let(:user_model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end

      define_schema do
        property :name, String
        property :age, Integer
      end
    end
  end

  it 'returns the patched client' do
    expect(patched_client).to eq(Anthropic::Client)
  end

  context 'with a new instance of the patched client' do
    it 'returns an instance of the patched client' do
      expect(patched_client.new).to be_an_instance_of(Anthropic::Client)
    end

    it 'does not require the response model argument' do
      client = patched_client.new
      expect { client.messages(parameters: {}) }.not_to raise_error(ArgumentError)
    end

    it 'does require the parameters argument' do
      client = patched_client.new
      expect { client.messages }.to raise_error(ArgumentError, 'missing keyword: :parameters')
    end

    it 'returns an object with the expected valid attribute values', vcr: 'anthropic_patch/valid_response' do
      client = patched_client.new

      user = client.messages(
        parameters: {
          model: 'claude-3-opus-20240229',
          messages: [{ role: 'user', content: 'Extract Jason is 25 years old' }]
        },
        response_model: user_model
      )

      expect(user.name).to eq('Jason')
      expect(user.age).to eq(25)
    end
  end

  context 'with validation context' do
    let(:client) { patched_client.new }
    let(:parameters) do
      {
        model: 'claude-3-opus-20240229',
        messages: [
          {
            role: 'user',
            content: 'Answer the question: %<question>s with the text chunk: %<text_chunk>s'
          }
        ]
      }
    end

    it 'returns an object with the expected valid attribute values', vcr: 'anthropic_patch/with_validation_context' do
      user = client.messages(
        parameters:,
        response_model: user_model,
        validation_context: { question: 'What is your name and age?',
                              text_chunk: 'my name is Jason and I turned 25 years old yesterday' }
      )

      expect(user.name).to eq('Jason')
      expect(user.age).to eq(25)
    end
  end

  context 'with an invalid response model' do
    let(:invalid_model) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'InvalidModel'
        end

        define_schema do
          property :name, String
          property :age, Integer
        end
      end
    end

    let(:client) { patched_client.new }
    let(:parameters) do
      {
        model: 'claude-3-opus-20240229',
        messages: [{ role: 'user', content: 'Extract Jason is 25 years old' }]
      }
    end

    it 'raises an error when the response model is invalid', vcr: 'anthropic_patch/invalid_response' do
      expect do
        client.messages(parameters:, response_model: invalid_model)
      end.to raise_error(Instructor::ValidationError)
    end
  end

  describe 'mode support' do
    it 'uses ANTHROPIC_TOOLS mode by default' do
      expect(Instructor::Anthropic.mode).to eq(Instructor::Mode::ANTHROPIC_TOOLS)
    end

    it 'accepts mode parameter on initialization' do
      Instructor.from_anthropic(Anthropic::Client, mode: Instructor::Mode::ANTHROPIC_JSON)
      expect(Instructor::Anthropic.mode).to eq(Instructor::Mode::ANTHROPIC_JSON)
    end

    context 'with ANTHROPIC_TOOLS mode' do
      it 'sets the mode correctly' do
        Instructor.from_anthropic(Anthropic::Client, mode: Instructor::Mode::ANTHROPIC_TOOLS)
        expect(Instructor::Anthropic.mode).to eq(Instructor::Mode::ANTHROPIC_TOOLS)
      end
    end

    context 'with ANTHROPIC_JSON mode' do
      it 'sets the mode correctly' do
        Instructor.from_anthropic(Anthropic::Client, mode: Instructor::Mode::ANTHROPIC_JSON)
        expect(Instructor::Anthropic.mode).to eq(Instructor::Mode::ANTHROPIC_JSON)
      end
    end

    context 'with ANTHROPIC_REASONING_TOOLS mode' do
      it 'sets the mode correctly' do
        Instructor.from_anthropic(Anthropic::Client, mode: Instructor::Mode::ANTHROPIC_REASONING_TOOLS)
        expect(Instructor::Anthropic.mode).to eq(Instructor::Mode::ANTHROPIC_REASONING_TOOLS)
      end
    end

    context 'with ANTHROPIC_PARALLEL_TOOLS mode' do
      it 'sets the mode correctly' do
        Instructor.from_anthropic(Anthropic::Client, mode: Instructor::Mode::ANTHROPIC_PARALLEL_TOOLS)
        expect(Instructor::Anthropic.mode).to eq(Instructor::Mode::ANTHROPIC_PARALLEL_TOOLS)
      end
    end
  end
end
