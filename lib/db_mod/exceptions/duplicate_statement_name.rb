require_relative 'base'

module DbMod
  module Exceptions
    # Raised when an attempt has been made to
    # define or prepare statements for a module that includes
    # more than one statement with the same name.
    class DuplicateStatementName < Base
    end
  end
end
