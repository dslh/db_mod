$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'db_mod/version'

Gem::Specification.new do |s|
  s.name        = 'db_mod'
  s.version     = DbMod::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Doug Hammond']
  s.email       = ['d.lakehammond@gmail.com']
  s.summary     = 'Ruby framework for building modular db-access libs.'
  s.description = 'Organize your database-intensive batch scripts with db_mod.'
  s.license     = 'MIT'

  s.add_runtime_dependency 'pg'
  s.add_runtime_dependency 'docile'

  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-mocks'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'bundler'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = %w(lib)
end
