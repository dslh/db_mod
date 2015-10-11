require_relative 'base'

module DbMod
  module Exceptions
    # Raised when an attempt has been made to
    # access db_mod functionality without first
    # creating or supplying a connection object.
    class ConnectionNotSet < Base
    end
  end
end
