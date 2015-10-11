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
      # Not yet implemented.
    end
  end
end
