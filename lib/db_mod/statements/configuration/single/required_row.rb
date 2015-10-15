module DbMod
  module Statements
    module Configuration
      module Single
        # Wrapper for a statement or prepared method that returns
        # only the first row of the result set as a hash, to save
        # manual unboxing. Raises an error unless exactly one row
        # is returned.
        #
        #  def_statement(:a, 'SELECT a, b FROM foo').single(:row)
        #
        #  def do_stuff
        #    a # => { 'a' => '1', 'b' => '2'
        #  end
        module RequiredRow
          # Enables this module to be passed to
          # {DbMod::Statements::Configuration.process_method_results} as the
          # +wrapper+ function, where it will return the first row of the
          # result set, or raise an exception if exactly one row is not
          # returned.
          #
          # @param results [Object] SQL result set
          # @return [Hash<String,String>]
          #   the first row of the SQL result set returned by the query
          def self.call(results)
            fail DbMod::Exceptions::NoResults unless results.any?
            fail DbMod::Exceptions::TooManyResults if results.count > 1

            results[0]
          end
        end
      end
    end
  end
end
