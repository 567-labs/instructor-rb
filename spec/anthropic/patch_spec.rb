# frozen_string_literal: true

require 'spec_helper'
require_relative '../helpers/anthropic_test_helpers'

RSpec.describe Instructor::Anthropic::Patch do
  include AnthropicTestHelpers
  
  # Set up our test environment before each example
  before(:each) do
    @patched_client = setup_anthropic_test_env
  end
  
  # Clean up after each example
  after(:each) do
    teardown_anthropic_test_env
  end
  
  let(:client) { @patched_client.new }
  
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

  it 'returns a class that inherits from the client' do
    expect(@patched_client.superclass).to eq(AnthropicTestHelpers::MockAnthropicSDK::Client)
  end

  context 'with a new instance of the patched client' do
    it 'returns an instance of the patched client class' do
      expect(client).to be_a(AnthropicTestHelpers::MockAnthropicSDK::Client)
    end

    it 'returns an object with the expected valid attribute values' do
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

    it 'returns an object with the expected valid attribute values' do
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
end