require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'db_mod'

require 'bundler'
Bundler.setup :default, :test
require 'pg'
require 'byebug' unless RUBY_VERSION < '2.0.0'

# This is used as a default value
ENV['USER'] ||= 'env_user'
