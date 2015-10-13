require_relative 'parameters'

module DbMod
  module Statements
    # Provides the +def_statement+ function which allows
    # {DbMod} modules to declare SQL statements that can
    # then be executed later using a specially defined
    # instance method.
    #
    # To declare prepared statements, see +def_prepared+
    # in {DbMod::Statements::Prepared}.
    #
    # def_statement
    # -------------
    #
    # +def_statement+ accepts two parameters:
    # * `name` [Symbol]: The name that will be given to the
    #   method that can be used to execute the SQL statement
    #   and return the result.
    # * `sql` [String]: The SQL statement that shoul be executed
    #   when the method is called. Parameters may be declared
    #   using the $ symbol followed by a number ($1, $2, $3) or
    #   a name ($one, $two, $under_scores). The two styles may
    #   not be mixed in the same statement. The defined function
    #   can then be passed parameters that will be used to fill
    #   in the statement before execution.
    module Statement
      # Defines a module-specific +def_statement+ function
      # for a module that has just had {DbMod} included.
      #
      # @param mod [Module]
      def self.setup(mod)
        Statement.define_def_statement(mod)
      end

      private

      # Add a +def_statement+ method definition to a module.
      # This method allows modules to declare SQL statements
      # that can be accessed via an instance method with
      # arbitrary name.
      #
      # @param mod [Module] a module with {DbMod} included
      def self.define_def_statement(mod)
        mod.class.instance_eval do
          define_method(:def_statement) do |name, sql|
            sql = sql.dup
            name = name.to_sym

            params = Parameters.parse_params! sql
            Statement.define_statement_method(mod, name, params, sql)
          end
        end
      end

      # Define a method in the given module with the given name
      # and parameters, that will call the given sql statement
      # and return the results.
      #
      # @param mod [Module] module declaring the method
      # @param name [Symbol] method name
      # @param params [Fixnum,Array<Symbol>]
      #   expected parameter count, or a list of argument names.
      #   An empty array produces a no-argument method.
      def self.define_statement_method(mod, name, params, sql)
        if params.is_a?(Array)
          if params.empty?
            define_no_args_statement_method(mod, name, sql)
          else
            define_named_args_statement_method(mod, name, params, sql)
          end
        else
          define_fixed_args_statement_method(mod, name, params, sql)
        end
      end

      # Define a no-argument method with the given name
      # that will execute the given sql statement and return
      # the result.
      #
      # @param mod [Module] {DbMod} enabled module
      #   where the method will be defined
      # @param name [Symbol] name of the method to be defined
      # @param sql [String] parameterless SQL statement to execute
      def self.define_no_args_statement_method(mod, name, sql)
        Statements.configurable_method mod, name, ->() { query(sql) }
      end

      # Define a method with the given name, that accepts the
      # given set of named parameters that will be used to execute
      # the given SQL query.
      #
      # @param mod [Module] {DbMod} enabled module
      # @param name [Symbol] name of the method to be defined
      # @param params [Array<Symbol>] parameter names and order
      def self.define_named_args_statement_method(mod, name, params, sql)
        method = lambda do |*args|
          args = Parameters.valid_named_args! params, args
          conn.exec_params(sql, args)
        end

        Statements.configurable_method mod, name, method
      end

      # Define a method with the given name that accepts a fixed number
      # of arguments, that will be used to execute the given SQL query.
      #
      # @param mod [Module] {DbMod} enabled module where the method
      #   will be defined
      # @param name [Symbol] name of the method to be defined
      # @param count [Fixnum] arity of the defined method,
      #   the number of parameters that the SQL statement requires
      def self.define_fixed_args_statement_method(mod, name, count, sql)
        method = lambda do |*args|
          Parameters.valid_fixed_args!(count, args)

          conn.exec_params(sql, args)
        end

        Statements.configurable_method mod, name, method
      end
    end
  end
end
