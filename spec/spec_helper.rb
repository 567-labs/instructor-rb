# frozen_string_literal: true

require 'instructor'
require 'pry-byebug'
require 'vcr'
require 'webmock/rspec'
require 'rspec/json_expectations'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<OPENAI_KEY_PLACEHOLDER>') { ENV.fetch('OPENAI_API_KEY', 'XXXXX') }
  config.filter_sensitive_data('<ANTHROPIC_KEY_PLACEHOLDER>') { ENV.fetch('ANTHROPIC_API_KEY', 'XXXXX') }
  
  # Match requests on method, URI, and body but not headers (which can change)
  config.default_cassette_options = {
    match_requests_on: [:method, :uri, :body]
  }
  
  # Allow HTTP connections when no cassette is inserted
  config.allow_http_connections_when_no_cassette = true
  
  # Ignore requests to Anthropic API in the Anthropic tests
  config.ignore_request do |request|
    uri = URI(request.uri)
    uri.host == 'api.anthropic.com' && ENV['IGNORE_ANTHROPIC_REQUESTS'] == 'true'
  end
  
  # Maintain the proper formatting of JSON attributes in cassettes
  config.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name == 'ASCII-8BIT' ||
    !http_message.body.valid_encoding?
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Disable all real HTTP connections for tests by default
  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  # Re-enable connections for tests that specifically need them
  config.after(:each) do
    WebMock.allow_net_connect! if ENV['VCR_RECORD_MODE'] == 'all'
  end
end

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_API_KEY', 'XXXXX')
end

# The Anthropic SDK beta doesn't use a configure pattern
# API keys are passed to the client when it's instantiated
# But we can set a default API key for tests
ENV['ANTHROPIC_API_KEY'] ||= 'sk_ant_test_key'
