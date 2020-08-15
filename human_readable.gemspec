# frozen_string_literal: true

# Copyright 2020 Mack Earnhardt

require_relative 'lib/human_readable/version'

Gem::Specification.new do |spec|
  spec.name          = 'human_readable'
  spec.version       = HumanReadable::VERSION
  spec.authors       = ['Mack Earnhardt']
  spec.email         = ['mack@agilereasoning.com']

  spec.summary       = 'Human readable random tokens with no ambiguous characters'
  spec.description   = <<~DESC
    Human readable random tokens with no ambiguous characters

    Tranlates invalid characters to their most likely original value
    and validates using a checksum.
  DESC
  spec.homepage      = 'https://github.com/MacksMind/human_readable'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.1')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(File.expand_path(__dir__)) do
      `find lib -name '*.rb' -print0`.split("\x0") +
        `find . -name '*.txt' -print0`.split("\x0") +
        `find . -name '*.md' -print0`.split("\x0")
    end
  # spec.bindir        = 'exe'
  # spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
