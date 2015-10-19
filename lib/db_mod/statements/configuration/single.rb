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
      # is via {MethodConfiguration#single}, which is available
      # when defining a statement method or prepared method:
      #
      #  def_statement(:a, 'SELECT name FROM a WHERE id=$1') { single(:value) }
      #  def_prepared(:b, 'SELECT id FROM b WHERE x > $y') { single(:column) }
      #  def_prepared(:c, 'SELECT * FROM c WHERE id = $id') { single(:row) }
      #
      #  def do_stuff
      #    a(1)    # => "foo"
      #    b(y: 2) # => ['1','2','3',...]
      #    c id: 3 # => Hash
      #  end
      #
      # +.single(:row)+ and +.single(:value)+ will return the first
      # row or the first value of the first row respectively, or +nil+
      # if no results are found. To generate a
      # {DbMod::Exceptions::NoResults} failure
      # instead of returning +nil+, use +.single(:row!)+ or
      # +.single(:value!)+.
      module Single
        # List of allowed parameters for {MethodConfiguration#single},
        # and the methods used to process them.
        COERCERS = {
          value: Single::Value,
          value!: Single::RequiredValue,
          row: Single::Row,
          row!: Single::RequiredRow,
          column: Single::Column
        }

        # Extend the given method definition with additional
        # result coercion.
        #
        # @param definition [Proc] base method definition
        # @param config [MethodConfiguration] method configuration
        def self.extend(definition, config)
          type = config[:single]
          return definition if type.nil?

          Configuration.attach_result_processor definition, COERCERS[type]
        end
      end
    end
  end
end
