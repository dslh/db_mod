require_relative 'base'

module DbMod
  module Exceptions
    # Raised when an attempt has been made to
    # start a transaction on a connection that
    # already has one open.
    class AlreadyInTransaction < Base
    end
  end
end
