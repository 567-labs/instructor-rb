# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'running an OpenAI function call' do
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

  let(:client) { Instructor.from_openai(OpenAI::Client, mode: :function_calling).new }

  let(:parameters) do
    {
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: 'Extract Jason is 25 years old' }]
    }
  end

  let(:response_model) { user_model }

  it 'returns a single object with the expected valid attribute values', vcr: 'features/openai/basic_spec/valid_response' do
    user = client.chat(parameters:, response_model:)

    expect(user.name).to eq('Jason')
    expect(user.age).to eq(25)
  end
end
