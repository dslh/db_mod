require_relative 'base'

module DbMod
  module Exceptions
    # Raised by a statement or prepared method that
    # has been configured using {ConfigurableMethod#single},
    # when a result set expected to contain at least one
    # result does not.
    class NoResults < Base
    end
  end
end
