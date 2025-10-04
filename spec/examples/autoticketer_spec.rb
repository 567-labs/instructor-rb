# frozen_string_literal: true

require 'spec_helper'
require_relative '../helpers/autoticketer_models'

RSpec.describe 'Auto-ticketer' do
  RSpec.configure do |c|
    c.include AutoticketerModels
  end

  let(:client) { Instructor.from_openai(OpenAI::Client, mode: :function_calling).new }

  let(:data) do
    <<~DATA
      Alice: Hey team, we have several critical tasks we need to tackle for the upcoming release. First, we need to work on improving the authentication system. It's a top priority.

      Bob: Got it, Alice. I can take the lead on the authentication improvements. Are there any specific areas you want me to focus on?

      Alice: Good question, Bob. We need both a front-end revamp and back-end optimization. So basically, two sub-tasks.

      Carol: I can help with the front-end part of the authentication system.

      Bob: Great, Carol. I'll handle the back-end optimization then.

      Alice: Perfect. Now, after the authentication system is improved, we have to integrate it with our new billing system. That's a medium priority task.

      Carol: Is the new billing system already in place?

      Alice: No, it's actually another task. So it's a dependency for the integration task. Bob, can you also handle the billing system?

      Bob: Sure, but I'll need to complete the back-end optimization of the authentication system first, so it's dependent on that.

      Alice: Understood. Lastly, we also need to update our user documentation to reflect all these changes. It's a low-priority task but still important.

      Carol: I can take that on once the front-end changes for the authentication system are done. So, it would be dependent on that.

      Alice: Sounds like a plan. Let's get these tasks modeled out and get started.
    DATA
  end

  def generate(data)
    client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            "content": 'The following is a transcript of a meeting between a manager and their team. The manager is assigning tasks to their team members and creating action items for them to complete.'
          },
          {
            "role": 'user',
            "content": "Create the action items for the following transcript: #{data}"
          }
        ]
      },
      response_model: AutoticketerModels::ActionItems
    )
  end

  it 'generates the proper json-schema', vcr: 'autoticketer/generate' do
    result = generate(data)

    expect(result.as_json).to include_json(
      {
      "items": [
         {
            "id": 1,
            "name": "Improve Authentication System",
            "description": "Work on front-end revamp and back-end optimization for the authentication system",
            "priority": "High",
            "assignees": [
            "Bob",
            "Carol"
            ],
            "subtasks": [
            {
               "id": 2,
               "name": "Front-end Revamp"
            },
            {
               "id": 3,
               "name": "Back-end Optimization"
            }
            ],
            "dependencies": nil
         },
         {
            "id": 4,
            "name": "Integrate Authentication with Billing System",
            "description": "Integrate the improved authentication system with the new billing system",
            "priority": "Medium",
            "assignees": [
            "Bob"
            ],
            "subtasks": nil,
            "dependencies": [
            1
            ]
         },
         {
            "id": 5,
            "name": "Update User Documentation",
            "description": "Update user documentation to reflect changes in authentication and billing systems",
            "priority": "Low",
            "assignees": [
            "Carol"
            ],
            "subtasks": nil,
            "dependencies": [
            2
            ]
         }
      ]
      }
    )
  end
end
