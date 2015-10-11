require_relative 'params'

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
    # def_prepared
    # ------------
    #
    # +def_prepared+ accepts two parameters:
    # * `name` [Symbol]: The name that will be given to
    #   the prepared statement. A method will also be defined
    #   on the module with the same name which will call the
    #   statement and return the result.
    # * `sql` [String]: The SQL statement to be prepared.
    #   Parameters may be declared using the $ symbol followed
    #   by a number ($1, $2, $3) or a name ($one, $two, $under_scores).
    #   The two styles may not be mixed in the same statement.
    #   The defined function can then be passed parameters
    #   that will be used when the statement is executed.
    #
    # ### example
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
      include Params

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

      # Add a +def_prepared+ method definition to a module.
      # This method allows modules to declare named SQL statements
      # that will be prepared when the database connection is
      # established, and that can be accessed via an instance
      # method with the same name.
      #
      # @param mod [Module] a module with {DbMod} included
      def self.define_def_prepared(mod)
        mod.class.instance_eval do
          define_method(:def_prepared) do |name, sql|
            sql = sql.dup
            name = name.to_sym

            params = Params.parse_params! sql
            prepared_statements[name] = sql
            Prepared.define_prepared_method(mod, name, params)
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

      # Define a method in the module with the given name
      # and parameters, that will call the prepared statement
      # with the same name.
      #
      # @param mod [Module] module declaring the metho
      # @param name [Symbol] method name
      # @param params [Fixnum,Array<Symbol>]
      #   expected parameter count, or a list of argument names.
      #   An empty array produces a no-argument method.
      def self.define_prepared_method(mod, name, params)
        mod.expected_prepared_statement_parameters[name] = params

        if params.is_a?(Array)
          if params.empty?
            define_no_args_prepared_method(mod, name)
          else
            define_named_args_prepared_method(mod, name, params)
          end
        else
          define_fixed_args_prepared_method(mod, name, params)
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
      def self.define_no_args_prepared_method(mod, name)
        mod.instance_eval do
          define_method name, ->() { conn.exec_prepared(name.to_s) }
        end
      end

      # Define a method with the given name that accepts the
      # given set of named parameters, that will call the prepared
      # statement with the same name.
      #
      # @param mod [Module] {DbMod} enabled module
      #   where the method will be defined
      # @param name [Symbol] name of the method to be defined
      #   and the prepared query to be called.
      # @param params [Array<Symbol>] list of parameter names
      def self.define_named_args_prepared_method(mod, name, params)
        method = lambda do |*args|
          unless args.size == 1
            fail ArgumentError, "unexpected arguments: #{args.inspect}"
          end
          args = Params.valid_named_args! params, args.first
          conn.exec_prepared(name.to_s, args)
        end

        mod.instance_eval { define_method(name, method) }
      end

      # Define a method with the given name that accepts a fixed
      # number of arguments, that will call the prepared statement
      # with the same name.
      #
      # @param mod [Module] {DbMod} enabled module
      #   where the method will be defined
      # @param name [Symbol] name of the method to be defined
      #   and the prepared query to be called.
      # @param count [Fixnum] arity of the defined method,
      #   the number of parameters that the prepared statement
      #   requires
      def self.define_fixed_args_prepared_method(mod, name, count)
        method = lambda do |*args|
          unless args.size == count
            fail ArgumentError, "#{args.size} args given, #{count} expected"
          end

          conn.exec_prepared(name.to_s, args)
        end

        mod.instance_eval { define_method(name, method) }
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

          define_method(:expected_prepared_statement_parameters) do
            @expected_prepared_statement_parameters ||= {}
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