# frozen_string_literal: true

module AnthropicTestHelpers
  # Create a completely stubbed version of the Anthropic SDK
  module MockAnthropicSDK
    class MockToolResponse
      attr_reader :type, :id, :name, :input
      
      def initialize(name, input)
        @type = 'tool_use'
        @id = 'toolu_mock123'
        @name = name
        @input = input
      end
    end
    
    class MockTextResponse
      attr_reader :type, :text
      
      def initialize(text)
        @type = 'text'
        @text = text
      end
    end
    
    class MockResponse
      attr_reader :content, :id, :type, :role, :model
      
      def initialize(name = "Jason", age = 25, tool_name = "User")
        text_block = MockTextResponse.new("<thinking>Test thinking</thinking>")
        tool_block = MockToolResponse.new(tool_name, { "name" => name, "age" => age })
        
        @content = [text_block, tool_block]
        @id = "msg_mock123"
        @type = "message"
        @role = "assistant"
        @model = "claude-3-opus-20240229"
      end
    end
    
    class MockMessages
      def create(**params)
        if params[:tools].is_a?(Array) && params[:tools][0][:name] == "InvalidModel"
          MockResponse.new("Jason", 25, "InvalidModel")
        else
          MockResponse.new
        end
      end
    end
    
    class Client
      include Instructor::Anthropic::Patch
      
      attr_reader :api_key, :mock_messages
      
      def initialize(api_key: nil)
        @api_key = api_key || "test-key"
        @mock_messages = MockMessages.new
      end
      
      def messages(parameters: nil, response_model: nil, max_retries: 0, validation_context: nil)
        # If parameters are provided, use the patched method
        if parameters
          # This calls our implementation from Instructor::Anthropic::Patch
          super
        else
          # Just return the mock messages object for method chaining during tests
          @mock_messages
        end
      end
    end
  end
  
  # Setup method to replace the real Anthropic SDK with our mock
  def setup_anthropic_test_env
    # Store the original module
    @original_anthropic = Anthropic if defined?(Anthropic)
    
    # Replace with our mock
    Object.const_set(:Anthropic, MockAnthropicSDK)
    
    # Create a fresh patch that won't be affected by previous test runs
    patched_client = Instructor.from_anthropic(MockAnthropicSDK::Client)
    
    patched_client
  end
  
  # Teardown method to restore the original SDK
  def teardown_anthropic_test_env
    # Restore original module if it existed
    if defined?(@original_anthropic)
      Object.const_set(:Anthropic, @original_anthropic) 
      @original_anthropic = nil
    elsif Object.const_defined?(:Anthropic)
      # Remove our mock if original didn't exist
      Object.send(:remove_const, :Anthropic)
    end
  end
end