require_relative 'base'

module DbMod
  module Exceptions
    # Raised when an attempt is made to configure
    # a dynamically defined statement or prepared method
    # in an invalid way.
    class BadMethodConfiguration < Base
    end
  end
end
