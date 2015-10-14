require_relative 'statements/configuration'
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
    # Called when a module includes {DbMod},
    # defines module-level +def_statement+ and +def_prepared+ dsl methods.
    def self.setup(mod)
      DbMod::Statements::Prepared.setup(mod)
      DbMod::Statements::Statement.setup(mod)
    end
  end
end
