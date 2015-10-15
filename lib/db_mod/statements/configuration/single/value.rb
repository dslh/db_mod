module DbMod
  module Statements
    module Configuration
      module Single
        # Wrapper for a statement or prepared method that
        # returns the first column of the first returned row,
        # or +nil+ if no rows are returned by the query.
        #
        #  def_statement(:a, 'SELECT 1').single(:value)
        #
        #  def do_stuff
        #    a # => '1'
        #  end
        module Value
          # Enables this module to be passed to
          # {DbMod::Statements::Configuration.process_method_results} as the
          # +wrapper+ function, where it will return the first column of the
          # first row of the result set, or +nil+ if no results are returned.
          #
          # @param results [Object] SQL result set
          # @return [String,nil] the first column of the first returned row
          def self.call(results)
            return nil unless results.any?

            row = results[0]
            row[row.keys.first]
          end
        end
      end
    end
  end
end
