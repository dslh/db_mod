require_relative 'parameters'

module DbMod
  module Statements
    # Provides the +def_prepared+ function which allows
    # {DbMod} modules to declare prepared SQL statements
    # that will be added to the database connection when
    # {DbMod#db_connect} is called.
    #
    # For statements that are not prepared ahead of execution,
    # see +def_statement+ in {DbMod::Statements::Statement}.
    #
    # +def_prepared+ accepts two parameters:
    # * *name* [Symbol]: The name that will be given to
    #   the prepared statement. A method will also be defined
    #   on the module with the same name which will call the
    #   statement and return the result.
    # * *sql* [String]: The SQL statement to be prepared.
    #   Parameters may be declared using the $ symbol followed
    #   by a number +($1, $2, $3)+ or a name +($one, $two, $a_b)+.
    #   The two styles may not be mixed in the same statement.
    #   The defined function can then be passed parameters
    #   that will be used when the statement is executed.
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
    module Prepared
      # Defines a module-specific +def_prepared+ function
      # for a module that has just had {DbMod} included.
      #
      # @param mod [Module]
      def self.setup(mod)
        Prepared.define_def_prepared(mod)
        Prepared.define_prepared_statements(mod)
        Prepared.define_inherited_prepared_statements(mod)
        Prepared.define_prepare_all_statements(mod)
      end

      private

      # Add a +def_prepared+ method definition to a module.
      # This method allows modules to declare named SQL statements
      # that will be prepared when the database connection is
      # established, and that can be accessed via an instance
      # method with the same name.
      #
      # @param mod [Module] a module with {DbMod} included
      def self.define_def_prepared(mod)
        mod.class.instance_eval do
          define_method(:def_prepared) do |name, sql, &block|
            sql = sql.dup
            name = name.to_sym

            params = Parameters.parse_params! sql
            prepared_statements[name] = sql
            Prepared.define_prepared_method(mod, name, params, &block)
          end
        end
      end

      # Defines +prepare_all_statements+, a module method which
      # accepts a connection object and will prepare on it all of
      # the prepared statements that have been declared on the
      # module or any of its included modules.
      #
      # @param mod [Module] module that has {DbMod} included
      def self.define_prepare_all_statements(mod)
        mod.class.instance_eval do
          define_method(:prepare_all_statements) do |conn|
            inherited_prepared_statements.each do |name, sql|
              conn.prepare(name.to_s, sql)
            end
          end
        end
      end

      # Merge the prepared statements from a module
      # into a given hash. Fails if there are any
      # duplicates.
      #
      # @param statements [Hash] named list of prepared statements
      # @param klass [Class,Module] ancestor (hopefully a DbMod module)
      #   to collect prepared statements from
      def self.merge_statements(statements, klass)
        return unless klass.respond_to? :prepared_statements
        return if klass.prepared_statements.nil?

        klass.prepared_statements.each do |name, sql|
          fail DbMod::Exceptions::DuplicateStatementName if statements.key? name

          statements[name] = sql
        end
      end

      # Define a method in the given module with the given name
      # and parameters, that will call the prepared statement
      # with the same name.
      #
      # @param mod [Module] module declaring the method
      # @param name [Symbol] method name
      # @param params [Fixnum,Array<Symbol>]
      #   expected parameter count, or a list of argument names.
      #   An empty array produces a no-argument method.
      # @yield dsl block may be passed, which will be evaluated using a
      #   {Configuration::MethodConfiguration} object as scope
      def self.define_prepared_method(mod, name, params, &block)
        if params == []
          define_no_args_prepared_method(mod, name, &block)
        else
          define_prepared_method_with_args(mod, name, params, &block)
        end
      end

      # Define a no-argument method with the given name
      # that will call the prepared statement with the
      # same name.
      #
      # @param mod [Module] {DbMod} enabled module
      #   where the method will be defined
      # @param name [Symbol] name of the method to be defined
      #   and the prepared query to be called.
      # @yield dsl method configuration object may be passed
      def self.define_no_args_prepared_method(mod, name, &block)
        method = ->(*) { conn.exec_prepared(name.to_s) }
        Configuration.def_configurable mod, name, method, &block
      end

      # @param mod [Module] {DbMod} enabled module
      #   where the method will be defined
      # @param name [Symbol] name of the method to be defined
      #   and the prepared query to be called.
      # @param params [Fixnum,Array<Symbol>]
      #   expected parameter count, or a list of argument names.
      #   An empty array produces a no-argument method.
      def self.define_prepared_method_with_args(mod, name, params, &block)
        method = ->(*args) { conn.exec_prepared(name.to_s, args) }
        Configuration.def_configurable(mod, name, method, params, &block)
      end

      # Adds +prepared_statements+ to a module. This list of named
      # prepared statements will be added to the connection when
      # {DbMod#db_connect} is called.
      #
      # @param mod [Module]
      def self.define_prepared_statements(mod)
        mod.class.instance_eval do
          define_method(:prepared_statements) do
            @prepared_statements ||= {}
          end
        end
      end

      # Adds +inherited_prepared_statements+ to a module. This list
      # of named prepared statements declared on this module and all
      # included modules will be added to the connection when
      # {DbMod#db_connect} is called.
      def self.define_inherited_prepared_statements(mod)
        mod.class.instance_eval do
          define_method(:inherited_prepared_statements) do
            inherited = {}
            ancestors.each do |klass|
              Prepared.merge_statements(inherited, klass)
            end
            inherited
          end
        end
      end
    end
  end
end
