# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'running an OpenAI function with a multiple object response' do
  let(:user_model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Users'
      end

      define_schema do
        property :name, String
        property :age, Integer
      end
    end
  end

  let(:client) { Instructor.from_openai(OpenAI::Client, mode: Instructor::Mode::TOOLS).new }

  let(:parameters) do
    {
      model: 'gpt-3.5-turbo',
      messages: [
        { role: 'system', content: 'Extract the names and ages of all the users' },
        { role: 'user', content: 'Extract `Jason is 25 and Peter is 32`' }
      ]
    }
  end

  let(:response_model) { T::Array[user_model] }

  let(:users) { client.chat(parameters:, response_model:) }

  it 'returns valid objects', vcr: 'iterable_spec/valid_response' do
    users.each do |user|
      expect(user.valid?).to eq(true)
    end
  end

  it 'returns objects with valid types', vcr: 'iterable_spec/valid_response' do
    users.each do |user|
      expect(user.name).to be_a(String)
      expect(user.age).to be_a(Integer)
    end
  end

  it 'returns objects with the expected attribute values', vcr: 'iterable_spec/valid_response' do
    expect(users[0].name).to eq('Jason')
    expect(users[0].age).to eq(25)
    expect(users[1].name).to eq('Peter')
    expect(users[1].age).to eq(32)
  end
end
