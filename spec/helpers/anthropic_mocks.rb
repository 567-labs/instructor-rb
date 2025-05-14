# frozen_string_literal: true

require 'webmock/rspec'

# Helper module for mocking Anthropic API responses
module AnthropicMocks
  # Stub specifically for JSON::ParserError tests
  def stub_json_parser_error
    # Always raise a JSON::ParserError
    WebMock.stub_request(:post, "https://api.anthropic.com/v1/messages")
           .with(
             body: hash_including({
               "model" => "claude-3-opus-20240229",
               "messages" => []
             })
           )
           .to_return(
             status: 200,
             body: "{",  # Invalid JSON - will cause parser error
             headers: { 'Content-Type' => 'application/json' }
           )
  end

  # Create a valid Anthropic response with tool use
  def mock_valid_anthropic_response(name: "User", tool_name: "User", age: 25)
    {
      id: "msg_01CAc2AULyo9B56LG2wWcv1K",
      type: "message",
      role: "assistant",
      model: "claude-3-opus-20240229",
      content: [
        {
          type: "text",
          text: "<thinking>\nThe user has requested to extract information about a person named #{name} who is #{age} years old.\n\nTo fulfill this request, the relevant tool is the #{tool_name} function, which takes a name and age parameter and returns a #{tool_name} object.\n\nLooking at the provided information:\n- The name \"#{name}\" is directly provided\n- The age of #{age} is directly provided\n\nSince both required parameters for the #{tool_name} function are present in the input, we can proceed with calling the function.\n</thinking>"
        },
        {
          type: "tool_use",
          id: "toolu_01GUkii2wgqWVg4USCJmxPTM",
          name: tool_name,
          input: {
            name: name,
            age: age
          }
        }
      ],
      stop_reason: "tool_use",
      stop_sequence: nil,
      usage: {
        input_tokens: 486,
        cache_creation_input_tokens: 0,
        cache_read_input_tokens: 0,
        output_tokens: 172
      }
    }.to_json
  end

  # Create a response that will cause a validation error
  def mock_invalid_anthropic_response
    {
      id: "msg_0123cY1twtm2Mcunkca8Bd8ez",
      type: "message",
      role: "assistant",
      model: "claude-3-opus-20240229",
      content: [
        {
          type: "text",
          text: "<thinking>\nThe InvalidModel function expects a name and age parameter, both of which are provided in the user's request. The name is \"Jason\" and the age is 25, so we have all the necessary information to call the function.\n</thinking>"
        },
        {
          type: "tool_use",
          id: "toolu_014V2Nwe85htWeKVATUCcT4e",
          name: "InvalidModel",
          input: {
            name: "Jason",
            age: 25
          }
        }
      ],
      stop_reason: "tool_use",
      stop_sequence: nil,
      usage: {
        input_tokens: 488,
        cache_creation_input_tokens: 0,
        cache_read_input_tokens: 0,
        output_tokens: 122
      }
    }.to_json
  end

  # Setup the stubs for different test scenarios
  def stub_anthropic_requests
    # Stub for valid response
    WebMock.stub_request(:post, "https://api.anthropic.com/v1/messages")
           .with(
             body: hash_including({
               "model" => "claude-3-opus-20240229",
               "messages" => array_including(hash_including({ 
                 "role" => "user", 
                 "content" => "Extract Jason is 25 years old" 
               })),
               "tools" => array_including(hash_including({
                 "name" => "User" 
               }))
             })
           )
           .to_return(
             status: 200,
             body: mock_valid_anthropic_response,
             headers: { 'Content-Type' => 'application/json' }
           )

    # Stub for invalid model response
    WebMock.stub_request(:post, "https://api.anthropic.com/v1/messages")
           .with(
             body: hash_including({
               "model" => "claude-3-opus-20240229",
               "messages" => array_including(hash_including({ 
                 "role" => "user", 
                 "content" => "Extract Jason is 25 years old" 
               })),
               "tools" => array_including(hash_including({
                 "name" => "InvalidModel" 
               }))
             })
           )
           .to_return(
             status: 200,
             body: mock_invalid_anthropic_response,
             headers: { 'Content-Type' => 'application/json' }
           )

    # Stub for validation context
    WebMock.stub_request(:post, "https://api.anthropic.com/v1/messages")
           .with(
             body: hash_including({
               "model" => "claude-3-opus-20240229",
               "messages" => array_including(hash_including({ 
                 "role" => "user", 
                 "content" => "Answer the question: What is your name and age? with the text chunk: my name is Jason and I turned 25 years old yesterday" 
               })),
               "tools" => array_including(hash_including({
                 "name" => "User" 
               }))
             })
           )
           .to_return(
             status: 200,
             body: mock_valid_anthropic_response,
             headers: { 'Content-Type' => 'application/json' }
           )

    # Default stub for any other request
    WebMock.stub_request(:post, "https://api.anthropic.com/v1/messages")
           .to_return(
             status: 200,
             body: mock_valid_anthropic_response,
             headers: { 'Content-Type' => 'application/json' }
           )
  end
end