# Send coverage report to codeclimate when a repo token is given
if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
else
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'db_mod'

require 'bundler'
Bundler.setup :default, :test
require 'pg'
require 'byebug' unless RUBY_VERSION < '2.0.0'

# This is used as a default value
ENV['USER'] ||= 'env_user'
