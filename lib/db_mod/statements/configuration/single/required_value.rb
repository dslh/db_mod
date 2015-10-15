module DbMod
  module Statements
    module Configuration
      module Single
        # Wrapper for a statement or prepared method that returns
        # the first column of the first returned row. Strictly enforces
        # that exactly one row should be returned by the SQL result, and
        # will fail if zero or more than one row is returned.
        #
        #  def_statement(:a, 'SELECT 1').single(:value!)
        #
        #  def do_stuff
        #    a # => '1'
        #  end
        module RequiredValue
          # Enables this module to be passed to
          # {DbMod::Statements::Configuration.process_method_results} as the
          # +wrapper+ function, where it will return the first column of the
          # first row of the result set, or fail if anything other than
          # exactly one row is returned.
          #
          # @param results [Object] SQL result set
          # @return [String] the first column of the first returned row
          def self.call(results)
            fail DbMod::Exceptions::NoResults unless results.any?
            fail DbMod::Exceptions::TooManyResults if results.count > 1

            row = results[0]
            row[row.keys.first]
          end
        end
      end
    end
  end
end
