#!/usr/bin/env rake
# frozen_string_literal: true

# No longer require bundle exec
Gem.use_gemdeps 'Gemfile'

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec
