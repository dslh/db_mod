require_relative 'single/value'
require_relative 'single/required_value'
require_relative 'single/row'
require_relative 'single/required_row'
require_relative 'single/column'

module DbMod
  module Statements
    module Configuration
      # Provides convenience extensions for statement and
      # prepared methods that return only a single result,
      # row, or column. The normal way to access this functionality
      # is via {ConfigurableMethod#single}, which is available
      # when defining a statement method or prepared method:
      #
      #  def_statement(:a, 'SELECT name FROM a WHERE id=$1').single(:value)
      #  def_prepared(:b, 'SELECT id FROM b WHERE value > $min').single(:column)
      #  def_prepared(:c, 'SELECT * FROM c WHERE id = $id').single(:row)
      #
      #  def do_stuff
      #    a # => "foo"
      #    b # => ['1','2','3',...]
      #    c # => Hash
      #  end
      #
      # +.single(:row)+ and +.single(:value)+ will return the first
      # row or the first value of the first row respectively, or +nil+
      # if no results are found. To generate a
      # {DbMod::Exceptions::NoResults} failure
      # instead of returning +nil+, use +.single(:row!)+ or
      # +.single(:value!)+.
      module Single
        # For process_method_results
        Configuration = DbMod::Statements::Configuration

        # List of allowed parameters for {#single},
        # and the methods used to process them.
        COERCERS = {
          value: Single::Value,
          value!: Single::RequiredValue,
          row: Single::Row,
          row!: Single::RequiredRow,
          column: Single::Column
        }

        # Extend a method so that only some singular part of
        # the SQL result set is returned.
        # See above for more details.
        #
        # @param mod [Module] module where the method has been defined
        # @param name [Symbol] method name
        # @param type [Symbol] one of {SINGLE_TYPES}
        def self.extend_method(mod, name, type)
          unless COERCERS.key? type
            fail ArgumentError, "#{type} not in #{COERCERS.keys.join ', '}"
          end

          Configuration.process_method_results(mod, name, COERCERS[type])
        end
      end
    end
  end
end
