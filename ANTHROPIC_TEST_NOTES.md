# Anthropic SDK Integration Notes

This document contains information about integrating and testing the official Anthropic SDK with Instructor-rb.

## Current Status

- The OpenAI integration works correctly with all tests passing.
- The Anthropic integration code has been updated to use the official Anthropic SDK (`anthropic-sdk-beta`) instead of `ruby-anthropic`.
- The Anthropic tests are currently failing, likely due to mocking/stubbing issues.

## Changes Made

1. Updated the gemspec to use `anthropic-sdk-beta` (~> 0.1.0.pre.beta.6) instead of `ruby-anthropic`
2. Updated imports in `lib/instructor.rb` to require 'anthropic' instead of 'ruby-anthropic'
3. Modified the Anthropic patch implementation to match the new SDK's API:
   - Updated message creation to use the new tools parameter structure
   - Added the beta header for tools support
   - Updated the client creation and message sending process

4. Updated the Response class to handle the new response format from the SDK:
   - Modified content and tool_calls methods to navigate the new structure
   - Updated the arguments method to extract input from tool calls

## Test Failures

The Anthropic tests are failing for several reasons:

1. **Mocking/Stubbing Issues**: The Anthropic SDK uses a complex architecture that's difficult to mock completely.
2. **VCR Configuration**: The VCR setup and the SDK's HTTP request mechanism don't interact well.
3. **JSON Parsing Errors**: We're seeing issues with serializing/deserializing response objects when testing.

## Recommendations

1. **Focus on Manual Testing**: Ensure the code works with real API calls before focusing on test coverage.
2. **Create New VCR Cassettes**: Record fresh VCR cassettes for the Anthropic tests with the new SDK.
3. **Simplify Test Structure**: Consider more focused tests that isolate the integration points.

## Next Steps

1. Complete a manual end-to-end test of the Anthropic integration.
2. Create a new test file specifically for the Anthropic SDK integration.
3. Consider adding test helpers specifically for the Anthropic SDK structure.

## Notes on The Anthropic SDK

The Anthropic SDK has a different structure compared to the ruby-anthropic client:

1. It uses a client instance with nested resources (e.g., `client.messages.create`) instead of direct methods.
2. Configuration isn't global but per-client (passed at initialization).
3. Response objects have a different structure with nested content blocks.
4. The tools interface requires a specific beta header.

The integration work to adapt to these differences has been done, but more thorough testing is needed.