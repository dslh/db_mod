module DbMod
  module Statements
    module Configuration
      module Single
        # Wrapper for a statement or prepared method that returns
        # an array of the values from the first value of every row
        # returned by the SQL statement.
        #
        #  def_statement(:a, 'SELECT a FROM b').single(:column)
        #
        #  def do_stuff
        #    a # => ['a', 'b', 'c']
        #  end
        module Column
          # Enables this module to be passed to
          # {DbMod::Statements::Configuration.process_method_results} as the
          # +wrapper+ function, where it will return an array of the first
          # value from every row in the result set.
          #
          # @param results [Object] SQL result set
          # @return [Array<String>] an array of values from the first column
          def self.call(results)
            results.map { |row| row[row.keys.first] }
          end
        end
      end
    end
  end
end
