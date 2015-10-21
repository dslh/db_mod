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
    # +def_statement+ accepts two parameters:
    # * *name* [Symbol]: The name that will be given to the
    #   method that can be used to execute the SQL statement
    #   and return the result.
    # * *sql* [String]: The SQL statement that shoul be executed
    #   when the method is called. Parameters may be declared
    #   using the $ symbol followed by a number +($1, $2, $3)+ or
    #   a name +($one, $two, $under_scores)+. The two styles may
    #   not be mixed in the same statement. The defined function
    #   can then be passed parameters that will be used to fill
    #   in the statement before execution.
    #
    #  module MyModule
    #    include DbMod
    #
    #    def_prepared :my_prepared, <<-SQL
    #      SELECT *
    #        FROM stuff
    #       WHERE a = $1 AND b = $2
    #    SQL
    #
    #    def_prepared :my_named_prepared, <<-SQL
    #      SELECT *
    #        FROM stuff
    #       WHERE a = $a AND b = $b
    #    SQL
    #  end
    #
    #  include MyModule
    #  db_connect db: 'mydb'
    #  my_prepared(1,2)
    #  my_named_prepared(a: 1, b: 2)
    module Statement
      # Defines a module-specific +def_statement+ function
      # for a module that has just had {DbMod} included.
      #
      # @param mod [Module] module with {DbMod} included
      # @see DbMod.included
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
      # @raise ArgumentError if there is a problem parsing
      #   method parameters from the SQL statement
      def self.define_def_statement(mod)
        class << mod
          define_method(:def_statement) do |name, sql, &block|
            sql = sql.dup
            name = name.to_sym

            params = Parameters.parse_params! sql
            Statement.define_statement_method(self, name, params, sql, &block)
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
      # @param sql [String] sql statement to execute
      # @param block [Proc] A dsl block may be passed, which will be evaluated
      #   using a {Configuration::MethodConfiguration} object as scope
      # @see Configuration.def_configurable
      def self.define_statement_method(mod, name, params, sql, &block)
        if params == []
          Configuration.def_configurable(mod, name, ->(*) { query sql }, &block)
        else
          method = ->(*args) { conn.exec_params(sql, args) }
          Configuration.def_configurable(mod, name, method, params, &block)
        end
      end
    end
  end
end
