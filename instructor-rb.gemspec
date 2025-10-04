# frozen_string_literal: true

require_relative 'lib/instructor/version'

Gem::Specification.new do |spec|
  spec.name = 'instructor-rb'
  spec.version = Instructor::VERSION
  spec.authors = ['Sergio Bayona', 'Jason Liu']
  spec.email = ['bayona.sergio@gmail.com', 'jason@jxnl.co']

  spec.summary = 'Structured extraction in Ruby, powered by llms.'
  spec.description = 'Explore the power of LLM structured extraction in Ruby with the Instructor gem.'
  spec.homepage = 'https://github.com/instructor-ai/instructor-rb'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/instructor-ai/instructor-rb'
  spec.metadata['changelog_uri'] = 'https://github.com/instructor-ai/instructor-rb/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[spec/ .git .github Gemfile])
    end
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 6.0'
  spec.add_dependency 'easy_talk', '~> 2'
  spec.add_dependency 'ruby-anthropic', '~> 0.4'
  spec.add_dependency 'ruby-openai', '~> 8'
  spec.add_development_dependency 'pry-byebug', '~> 3.10'
  spec.add_development_dependency 'rake', '~> 13.1'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-json_expectations', '~> 2.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.29'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'webmock', '~> 3.13'
end
