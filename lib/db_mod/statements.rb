require_relative 'statements/configuration'
require_relative 'statements/default_method_settings'
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
    #
    # @param mod [Module] module that has had {DbMod} included
    # @see DbMod.included
    # @see DefaultMethodSettings
    # @see Prepared
    # @see Statement
    def self.setup(mod)
      DbMod::Statements::DefaultMethodSettings.setup(mod)
      DbMod::Statements::Prepared.setup(mod)
      DbMod::Statements::Statement.setup(mod)
    end
  end
end
