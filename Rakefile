require 'rubygems'
require 'bundler'
Bundler.setup :default, :test, :development

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

task :spec

require 'rainbow/ext/string' unless String.respond_to?(:color)
require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: [:rubocop, :inch, :spec]

require 'yard'
DOC_FILES = ['lib/**/*.rb', 'README.md']

YARD::Rake::YardocTask.new(:doc) do |t|
  t.files = DOC_FILES
end

require 'inch/rake'
Inch::Rake::Suggest.new
