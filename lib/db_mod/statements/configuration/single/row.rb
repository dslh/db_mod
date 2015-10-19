module DbMod
  module Statements
    module Configuration
      module Single
        # Wrapper for a statement or prepared method that returns
        # only the first row of the result set as a hash, to save
        # manual unboxing. Returns +nil+ if the query returns no
        # results.
        #
        #  def_statement(:a, 'SELECT a, b FROM foo').single(:row)
        #
        #  def do_stuff
        #    a # => { 'a' => '1', 'b' => '2'
        #  end
        module Row
          # Enables this module to be passed to
          # {DbMod::Statements::Configuration.attach_result_processor} as the
          # +wrapper+ function, where it will return the first row of the
          # result set, or +nil+ if the result set is empty.
          #
          # @param results [Object] SQL result set
          # @return [Hash<String,String>,nil]
          #   the first row of the SQL result set returned by the query
          def self.call(results)
            return nil unless results.any?

            results[0]
          end
        end
      end
    end
  end
end
