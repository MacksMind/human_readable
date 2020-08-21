# frozen_string_literal: true

# Copyright 2020 Mack Earnhardt

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

CLOBBER << 'generate.html'
CLOBBER << 'validate.html'

namespace :human_readable do
  desc 'Performance profile'
  task :performance do
    require_relative 'lib/human_readable'
    require 'ruby-prof'
    require 'stringio'

    # Warmup memoizations and grab a valid token
    token = HumanReadable.valid_token?(HumanReadable.generate)

    RubyProf.measure_mode = RubyProf::PROCESS_TIME

    generate = RubyProf::Profile.new
    generate.exclude_methods!(Integer, :times)
    generate.start
    100.times { HumanReadable.generate }
    generate.stop

    File.open('generate.html', 'w') do |f|
      RubyProf::CallStackPrinter.new(generate).print(f, title: 'HumanReadable.generate')
    end

    validate = RubyProf::Profile.new
    validate.exclude_methods!(Integer, :times)
    validate.start
    100.times { HumanReadable.valid_token?(token) }
    validate.stop

    File.open('validate.html', 'w') do |f|
      RubyProf::CallStackPrinter.new(validate).print(f, { title: 'HumanReadable.valid_token?' })
    end
  end
end
