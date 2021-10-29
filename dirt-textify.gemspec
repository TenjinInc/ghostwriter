# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ghostwriter/version'

Gem::Specification.new do |spec|
   spec.name    = 'ghostwriter'
   spec.version = Ghostwriter::VERSION
   spec.authors = ['Robin Miller']
   spec.email   = ['robin@tenjin.ca']

   spec.summary     = 'Converts HTML to plain text'
   spec.description = <<~DESC
      Converts HTML to plain text, preserving as much legibility and functionality as possible.

      Ideal for providing a plaintext multipart segment of email messages.
   DESC
   spec.homepage = 'https://github.com/TenjinInc/ghostwriter'
   spec.license  = 'MIT'

   spec.files = `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
   end

   spec.bindir        = 'exe'
   spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
   spec.require_paths = ['lib']

   spec.required_ruby_version = '~> 2.4'

   spec.add_dependency 'nokogiri', '~> 1.12'

   spec.add_development_dependency 'bundler', '~> 2.2'
   spec.add_development_dependency 'rake', '~> 13.0'
   spec.add_development_dependency 'rspec', '~> 3.3'
   spec.add_development_dependency 'rubocop', '~> 1.22'
   spec.add_development_dependency 'rubocop-performance', '~> 1.11'
end
