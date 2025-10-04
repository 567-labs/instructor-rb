# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Instructor, '.class' do
  after { Instructor::OpenAI.mode = nil }

  it 'returns the default mode after patching' do
    described_class.from_openai(OpenAI::Client)
    expect(Instructor::OpenAI.mode).to eq(Instructor::Mode::TOOLS_STRICT)
  end

  it 'changes the mode to TOOLS_STRICT' do
    described_class.from_openai(OpenAI::Client, mode: Instructor::Mode::TOOLS_STRICT)
    expect(Instructor::OpenAI.mode).to eq(Instructor::Mode::TOOLS_STRICT)
  end

  it 'changes the mode to TOOLS' do
    described_class.from_openai(OpenAI::Client, mode: Instructor::Mode::TOOLS)
    expect(Instructor::OpenAI.mode).to eq(Instructor::Mode::TOOLS)
  end

  it 'supports legacy structured_output mode for backward compatibility' do
    described_class.from_openai(OpenAI::Client, mode: :structured_output)
    expect(Instructor::OpenAI.mode).to eq(:structured_output)
  end

  it 'supports legacy function_calling mode for backward compatibility' do
    described_class.from_openai(OpenAI::Client, mode: :function_calling)
    expect(Instructor::OpenAI.mode).to eq(:function_calling)
  end
end
