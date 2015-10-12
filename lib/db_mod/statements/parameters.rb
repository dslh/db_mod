module DbMod
  module Statements
    # Parsing and validation of query parameters
    # for prepared SQL statements
    module Parameters
      # Called when a {DbMod} dynamically defined method is called.
      # Assert that the named arguments given for the prepared statement
      # with the given name satisfy expectations. Returns a parameter array
      # as per {Parameters.parameter_array}.
      #
      # @param expected [Array<Symbol>] the parameters expected to be present
      # @param args [Array<Hash<Symbol>>] arguments given to the method being
      #   executed. The method should only be called with an options hash that
      #   contains exactly the parameter names given when the method was
      #   defined.
      # @return [Array] values to be passed to the prepared statement
      def self.valid_named_args!(expected, args)
        wrapped_hash! args

        args = args.first
        if args.size != expected.size
          fail ArgumentError, "#{args.size} args given, #{expected.size} needed"
        end

        parameter_array(expected, args)
      end

      # Called when a {DbMod} dynamically defined method is called.
      # Assert that the correct number of arguments has been provided.
      #
      # @param count [Fixnum] arity of the method being called.
      # @param args [Array] list of arguments given.
      def self.valid_fixed_args!(count, args)
        unless args.size == count
          fail ArgumentError, "#{args.size} args given, #{count} expected"
        end
      end

      # Called when a {DbMod} dynamically defined method is declared.
      # Parses parameters, named or numbered, from an SQL
      # statement. See the {Prepared} module documentation
      # for more. This method may modify the sql statement
      # to change named parameters to numbered parameters.
      # If the query uses numbered parameters, an integer
      # will be returned that is the arity of the statement.
      # If the query uses named parameters, an array of
      # symbols will be returned, giving the order in which
      # the named parameters should be fed into the
      # statement.
      #
      # @param sql [String] statement to prepare
      # @return [Fixnum,Array<Symbol>] description of
      #   prepared statement's parameters
      def self.parse_params!(sql)
        Parameters.valid_sql_params! sql
        numbered = sql.scan NUMBERED_PARAM
        named = sql.scan NAMED_PARAM

        if numbered.any?
          fail ArgumentError, 'mixed named and numbered params' if named.any?
          Parameters.parse_numbered_params! numbered
        else
          Parameters.parse_named_params! sql, named
        end
      end

      # Regex matching a numbered parameter
      NUMBERED_PARAM = /\$\d+/

      # Regex matching a named parameter
      NAMED_PARAM = /\$[a-z]+(?:_[a-z]+)*/

      # For validation, named or numbered parameter
      NAMED_OR_NUMBERED = /^\$(?:\d+|[a-z]+(?:_[a-z]+)*)$/

      private

      # Assert that the given parameter list is an array
      # containing a single hash of named parameter values.
      #
      # Raises {ArgumentError} otherwise.
      #
      # @param args [Array<Hash<Symbol>>] method arguments being validated
      def self.wrapped_hash!(args)
        unless args.size == 1
          fail ArgumentError, "unexpected arguments: #{args.inspect}"
        end

        unless args.first.is_a? Hash
          fail ArgumentError, "invalid argument: #{args.first.inspect}"
        end
      end

      # Convert the given named parameter hash into
      # an array containing the parameter values in
      # the order required to be supplied to the
      # SQL statement being executed.
      #
      # @param expected [Array<Symbol>] the parameters expected to be present
      # @param args [Hash] given parameters
      # @return [Array] values to be passed to the prepared statement
      def self.parameter_array(expected, args)
        expected.map do |arg|
          args[arg] || fail(ArgumentError, "missing arg #{arg}")
        end
      end

      # Fails if any parameters in an sql query aren't
      # in the expected format. They must either be
      # lower_case_a_to_z or digits only.
      def self.valid_sql_params!(sql)
        sql.scan(/\$[A-Za-z0-9_]+/) do |param|
          unless param =~ NAMED_OR_NUMBERED
            fail ArgumentError, "Invalid parameter #{param}"
          end
        end
      end

      # Validates the numbered parameters given (i.e. no gaps),
      # and returns the parameter count.
      #
      # @param params [Array<String>] '$1','$2', etc...
      # @return [Fixnum] parameter count
      def self.parse_numbered_params!(params)
        params.sort!
        params.uniq!
        if params.last[1..-1].to_i != params.length ||
           params.first[1..-1].to_i != 1
          fail ArgumentError, 'Invalid parameter list'
        end

        params.length
      end

      # Replaces the given list of named parameters in the
      # query string with numbered parameters, and returns
      # an array of symbols giving the order the parameters
      # should be fed into the prepared statement for execution.
      #
      # @param sql [String] the SQL statement. Will be modified.
      # @param params [Array<String>] '$one', '$two', etc...
      # @return [Array<Symbol>] unique list of named parameters
      def self.parse_named_params!(sql, params)
        unique_params = params.uniq
        params.each do |param|
          index = unique_params.index(param)
          sql[param] = "$#{index + 1}"
        end

        unique_params.map { |p| p[1..-1].to_sym }
      end
    end
  end
end
