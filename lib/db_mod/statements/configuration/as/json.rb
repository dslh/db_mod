module DbMod
  module Statements
    module Configuration
      module As
        # Coercer which converts an SQL result set
        # into a string formatted as a JSON array.
        # May be enabled for a prepared method or
        # statement method using +.as(:json)+:
        #
        #  def_statement(:a, 'SELECT a, b FROM foo') { as(:json) }
        #  def_prepared(:b, 'SELECT b, c FROM bar') { as(:json) }
        #
        #  def do_stuff
        #   a # => '[{"a":"x","b":"y"},...]'
        #  end
        class Json
          # Formats the SQL results as a JSON object.
          #
          # @param results [Object] SQL result set
          # @return [String] a JSON formatted string
          def self.call(results)
            # For compatibility with single(:row)
            return results.to_json if results.is_a? Hash

            results.to_a.to_json
          end
        end
      end
    end
  end
end
