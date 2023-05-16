# frozen_string_literal: true

require File.expand_path('lib/attach/version', __dir__)

# rubocop:disable Gemspec/RequireMFA
Gem::Specification.new do |s|
  s.name          = 'attach'
  s.description   = 'Attach documents & files to Active Record models'
  s.summary       = s.description
  s.required_ruby_version = '>= 2.6'
  s.homepage      = 'https://github.com/krystal/attach'
  s.version       = Attach::VERSION
  s.files         = Dir.glob('{lib,db}/**/*')
  s.require_paths = ['lib']
  s.authors       = ['Adam Cooke']
  s.email         = ['me@adamcooke.io']
  s.licenses      = ['MIT']
  s.add_runtime_dependency('activerecord', '>= 6.0')
  s.add_runtime_dependency('records_manipulator', '>= 1.0', '< 2.0')
end
# rubocop:enable Gemspec/RequireMFA
