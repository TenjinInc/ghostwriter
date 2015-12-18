# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dirt/textify/version'

Gem::Specification.new do |gemspec|
  gemspec.name     = "dirt-textify"
  gemspec.version  = Dirt::Textify::VERSION
  gemspec.authors  = ["Robin Miller"]
  gemspec.email    = ["robin@tenjin.ca"]

  gemspec.summary      = %q{Intelligently extracts plaintext from an HTML document.}
  gemspec.description  = %q{Transforms HTML into plaintext while preserving legilbility and functionality. }
  gemspec.homepage     = 'https://github.com/TenjinInc/dirt-textify'
  gemspec.license      = 'MIT'

  gemspec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  gemspec.bindir        = 'exe'
  gemspec.executables   = gemspec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gemspec.require_paths = ['lib']

  gemspec.add_dependency 'nokogiri'

  gemspec.add_development_dependency 'bundler', '~> 1.10'
  gemspec.add_development_dependency 'rake', '~> 10.0'
  gemspec.add_development_dependency 'rspec'
end
