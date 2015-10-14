require_relative 'as/csv'

module DbMod
  module Statements
    module Configuration
      # Contains coercers and other functions that allow
      # module instance methods returning an SQL result set
      # to be extended with additional result coercion and
      # formatting. The normal way to access this functionality
      # is via {DbMod::Statements::Configuration::ConfigurableMethod#as},
      # which is available when defining a statement method
      # or prepared method:
      #
      #  def_statement(:a, 'SELECT a, b, c FROM foo').as(:csv)
      #  def_prepared(:b, 'SELECT d, e, f FROM bar').as(:csv)
      module As
        # For extend_method
        Configuration = DbMod::Statements::Configuration

        # List of available result coercion methods.
        # Only keys defined here are allowed as arguments
        # to {DbMod::Statements::Configuration::ConfigurableMethod#as}.
        COERCERS = {
          csv: As::Csv
        }

        # Extend a method so that the SQL result set it
        # returns will be coerced to the given type.
        # See {COERCERS} for a list of defined coercion
        # methods.
        #
        # @param mod [Module] module where the method has been defined
        # @param name [Symbol] method name
        # @param type [Symbol] type to which result set should be coerced
        def self.extend_method(mod, name, type)
          unless COERCERS.key? type
            fail ArgumentError, "#{type} not in #{COERCERS.keys.join ', '}"
          end

          Configuration.extend_method(mod, name, COERCERS[type])
        end
      end
    end
  end
end
