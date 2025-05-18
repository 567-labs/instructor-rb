# instructor-rb

_Structured extraction in Ruby, powered by llms, designed for simplicity, transparency, and control._

---

[![Twitter Follow](https://img.shields.io/twitter/follow/jxnlco?style=social)](https://twitter.com/jxnlco)
[![Twitter Follow](https://img.shields.io/twitter/follow/sergiobayona?style=social)](https://twitter.com/sergiobayona)
[![Documentation](https://img.shields.io/badge/docs-available-brightgreen)](https://jxnl.github.io/instructor-rb)
[![GitHub issues](https://img.shields.io/github/issues/instructor-ai/instructor-js.svg)](https://github.com/instructor-ai/instructor-rb/issues)
[![Discord](https://img.shields.io/discord/1192334452110659664?label=discord)](https://discord.gg/DWHZdqpNgz)

Dive into the world of Ruby-based structured extraction, by OpenAI's function calling API, Ruby schema validation with type hinting. Instructor stands out for its simplicity, transparency, and user-centric design. Whether you're a seasoned developer or just starting out, you'll find Instructor's approach intuitive and steerable.

Check us out in [Python](https://jxnl.github.io/instructor/), [Elixir](https://github.com/thmsmlr/instructor_ex/), [PHP](https://github.com/cognesy/instructor-php/) and [Ruby](https://github.com/instructor-ai/instructor-rb).

If you want to port Instructor to another language, please reach out to us on [Twitter](https://twitter.com/jxnlco) we'd love to help you get started!

## Usage

To check out all the tips and tricks to prompt and extract data, check out the [documentation](https://instructor-ai.github.io/instructor-rb/tips/prompting/).

Installation is as simple as:

```bash
gem install instructor-rb
```


```Ruby
require 'instructor-rb'

OpenAI.configure do |config|
    config.access_token = ENV.fetch("OPENAI_ACCESS_TOKEN")
    config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID") # Optional.
end

class UserDetail
  include EasyTalk::Model
  
  define_schema do
    property :name, String
    property :age, Integer
  end
end
  
client = Instructor.from_openai(OpenAI::Client).new

user = client.chat(
parameters: {
    model: 'gpt-3.5-turbo',
    messages: [{ role: 'user', content: 'Extract Jason is 25 years old' }]
},
response_model: UserDetail
)

user.name
# => "Jason"
user.age
# => 25
```

## Why use Instructor?

The question of using Instructor is fundamentally a question of why to use zod.

1. **Powered by OpenAI** — Instructor is powered by OpenAI's function calling API. This means you can use the same API for both prompting and extraction.

2. **Ruby Schema Validation** — Instructor uses Ruby schema validation with type hinting. This means you can validate your data before using it.

## More Examples

If you'd like to see more check out our [cookbook](examples/index.md).

## Contributing

If you want to help out, checkout some of the issues marked as `good-first-issue` or `help-wanted`. Found [here](https://github.com/instructor-ai/instructor-rb/labels/good%20first%20issue). They could be anything from code improvements, a guest blog post, or a new cook book.

## License

This project is licensed under the terms of the MIT License.
