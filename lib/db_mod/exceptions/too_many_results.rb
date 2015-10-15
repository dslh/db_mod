require_relative 'base'

module DbMod
  module Exceptions
    # Raised by a statement or prepared method that
    # has been configured using {ConfigurableMethod#single},
    # when a result set expected to contain not more than
    # one result, in fact, does.
    class TooManyResults < Base
    end
  end
end
