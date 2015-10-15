require_relative 'as'
require_relative 'single'

module DbMod
  module Statements
    module Configuration
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
          @already_called = {}
        end

        # Extend the method by converting results into a given
        # format, using one of the coercion methods defined
        # under {DbMod::Statements::Configuration::As}.
        #
        # @param type [:csv,:json] output format for the method
        # @return [self]
        def as(type)
          called! :as

          Configuration::As.extend_method(@mod, @name, type)

          self
        end

        # Extend the method by extracting a singular part of
        # the result set, for queries expected to only return
        # one row, one column, or one row with a single value.
        # See {DbMod::Statements::Configuration::Single} for
        # more details.
        #
        # @param type [Symbol] see {SINGLE_TYPES}
        # @return [self]
        def single(type)
          called! :single

          Configuration::Single.extend_method(@mod, @name, type)

          self
        end

        private

        # Guard method which asserts that a configuration method
        # may not be called more than once, or else raises
        # {DbMod::Exceptions::BadMethodConfiguration}.
        #
        # @param method [Symbol] method being called
        def called!(method)
          if @already_called[method]
            fail Exceptions::BadMethodConfiguration, "#{method} already called"
          end

          @already_called[method] = true
        end
      end
    end
  end
end
