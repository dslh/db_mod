module DbMod
  module Statements
    module Configuration
      module As
        # Coercer which converts an SQL result set
        # into a string formatted as a JSON array.
        # May be enabled for a prepared method or
        # statement method using +.as(:json)+:
        #
        #  def_statement(:a, 'SELECT a, b FROM foo').as(:json)
        #  def_prepared(:b, 'SELECT b, c FROM bar').as(:json)
        #
        #  def do_stuff
        #   a # => '[{"a":"x","b":"y"},...]'
        #  end
        module Json
          # Enables this module to be passed to
          # {DbMod::Statements::Configuration.extend_method} as the +wrapper+
          # function, in which case it will retrieve the results
          # and format them as a JSON string using the column names
          # from the result set for the keys of each object.
          #
          # @param wrapped_method [Method] the method that has been wrapped
          # @param args [*] arguments
          #   expected to be passed to the wrapped method
          # @return [String] a JSON formatted string
          def self.call(wrapped_method, *args)
            results = wrapped_method.call(*args)

            # .map turns the result object into an array
            results.map { |x| x }.to_json
          end
        end
      end
    end
  end
end
