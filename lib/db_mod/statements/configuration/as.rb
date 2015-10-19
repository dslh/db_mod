require_relative 'as/csv'
require_relative 'as/json'

module DbMod
  module Statements
    module Configuration
      # Contains coercers and other functions that allow
      # module instance methods returning an SQL result set
      # to be extended with additional result coercion and
      # formatting. The normal way to access this functionality
      # is via {ConfigurableMethod#as},
      # which is available when defining a statement method
      # or prepared method:
      #
      #  def_statement(:a, 'SELECT a, b, c FROM foo').as(:csv)
      #  def_prepared(:b, 'SELECT d, e, f FROM bar').as(:csv)
      module As
        # List of available result coercion methods.
        # Only keys defined here are allowed as arguments
        # to {DbMod::Statements::Configuration::ConfigurableMethod#as}.
        COERCERS = {
          csv: As::Csv,
          json: As::Json
        }
      end
    end
  end
end
