require_relative 'statements/statement'
require_relative 'statements/prepared'

module DbMod
  # Functions allowing {DbMod} modules to declare
  # SQL statements that can be called later via
  # automatically declared instance methods.
  #
  # See {DbMod::Statements::Statement} for details on +def_statement+
  # and {DbMod::Statements::Prepared} for details on +def_prepared+.
  module Statements
  end
end
