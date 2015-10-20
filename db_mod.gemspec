$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'db_mod/version'

Gem::Specification.new do |s|
  s.name        = 'db_mod'
  s.version     = DbMod::VERSION
  s.platform    = Gem::Platform::RUBY
  s.author      = 'Doug Hammond'
  s.email       = ['d.lakehammond@gmail.com']
  s.homepage    = 'https://github.com/dslh/db_mod'
  s.summary     = 'Declarative, modular database library framework.'
  s.description = 'Framework for building modular database libraries.'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 1.9.3'

  s.add_runtime_dependency 'pg'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'codeclimate-test-reporter'
  s.add_development_dependency 'inch'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-mocks'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'yard'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = %w(lib)
end
