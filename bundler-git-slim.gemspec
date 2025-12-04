# frozen_string_literal: true

require_relative 'lib/bundler/git_slim'

Gem::Specification.new do |spec|
  spec.name          = 'bundler-git-slim'
  spec.version       = Bundler::GitSlim::VERSION
  spec.authors       = ['Your Name']
  spec.email         = ['you@example.com']

  spec.summary       = 'Bundler plugin that slims git-installed gems down to spec.files.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/yourname/bundler-git-slim'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.7'

  spec.files         = Dir['lib/**/*.rb', 'plugins.rb', 'README.md', 'LICENSE', 'bundler-git-slim.gemspec']
  spec.require_paths = ['lib']

  spec.add_dependency 'bundler', '>= 2.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'bundler_plugin' => 'true',
    'rubygems_mfa_required' => 'true'
  }
end
