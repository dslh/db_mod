module DbMod
  module Statements
    module Configuration
      module As
        # Coercer which converts an SQL result set
        # into a string formatted as a CSV document.
        # May be enabled for a prepared method or
        # statement method using +.as(:csv)+:
        #
        #  def_statement(:a, 'SELECT a, b FROM foo').as(:csv)
        #  def_prepared(:b, 'SELECT b, c FROM bar').as(:csv)
        #
        #  def do_stuff
        #    a # => "a,b\r\n1,2\r\n3,4\r\n..."
        #  end
        module Csv
          # Enables this module to be passed to
          # {DbMod::Statements::Configuration.extend_method} as the +wrapper+
          # function, in which case it will retrieve the results
          # and format them as a CSV document using the column names
          # from the result set.
          #
          # @param wrapped_method [Method] the method that has been wrapped
          # @param args [*] arguments
          #   expected to be passed to the wrapped method
          # @return [String] a CSV formatted document
          def self.call(wrapped_method, *args)
            results = wrapped_method.call(*args)

            headers = nil
            CSV.generate do |csv|
              results.each do |row|
                csv << (headers = row.keys) unless headers

                csv << headers.map { |col| row[col] }
              end
            end
          end
        end
      end
    end
  end
end