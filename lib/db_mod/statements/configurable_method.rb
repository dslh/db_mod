require 'db_mod/as'

module DbMod
  module Statements
    # Encapsulates a method that has just been defined
    # via the dsl exposed in {DbMod::Statements} so that
    # it can be extended with additional processing such
    # as result coercion.
    #
    # The pattern here is something similar to rack's middleware.
    # Calling any of the extension methods below will replace
    # the original method defined by +def_prepared+ or +def_statement+
    # with a wrapper function that may perform processing on given
    # arguments, pass them to the original function, then perform
    # additional processing on the result.
    class ConfigurableMethod
      # Encapsulate a method that has been newly defined
      # by a {DbMod} dsl function, for additional configuration.
      #
      # @param mod [Module] the {DbMod} enabled module
      #   where the method was defined
      # @param name [Symbol] the method name
      def initialize(mod, name)
        @mod = mod
        @name = name
      end

      # Extend the method by converting results into a given
      # format, using one of the coercion methods defined
      # under {DbMod::As}.
      #
      # @param type [Symbol] for now, only :csv is accepted
      # @return [self]
      def as(type)
        DbMod::As.extend_method(@mod, @name, type)

        self
      end
    end
  end
end
