require_relative 'as/csv'
require_relative 'as/json'

module DbMod
  module Statements
    module Configuration
      # Contains coercers and other functions that allow
      # module instance methods returning an SQL result set
      # to be extended with additional result coercion and
      # formatting. The normal way to access this functionality
      # is via {MethodConfiguration#as},
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

        # Extend the given method definition with additional
        # result coercion, if specified.
        #
        # @param definition [Proc] base method definition
        # @param config [MethodConfiguration] method configuration
        # @return [Proc] wrapped method definition, or the original
        #   definition if no coercion has been specified
        def self.extend(definition, config)
          type = config[:as]
          return definition if type.nil?

          Configuration.attach_result_processor definition, COERCERS[type]
        end
      end
    end
  end
end
