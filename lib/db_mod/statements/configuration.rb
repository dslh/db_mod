module DbMod
  module Statements
    # Provides additional functionality to statement and
    # prepared methods, allowing additional processing of
    # arguments and results using the dsl extensions
    # exposed via {ConfigurableMethod}.
    module Configuration
      # Used by submodules to when defining a method as declared by
      # +def_statement+ or +def_prepared+. Wraps the defined method
      # so that it may be extended with additional argument and
      # result processing.
      #
      # @param mod [Module] the module where the method has been declared
      # @param name [Symbol] the name of the module that has been defined
      # @param definition [Proc] method definition
      # @return [DbMod::Statements::ConfigurableMethod] dsl object for
      #   further extending the method
      def self.def_configurable(mod, name, definition)
        mod.instance_eval { define_method(name, definition) }

        ConfigurableMethod.new(mod, name)
      end

      # Used by {ConfigurableMethod} (and associated code) to wrap a defined
      # statement method or prepared method with additional parameter or result
      # processing. A wrapper method definition should be provided, which will
      # be called in place of the original method. It will be called with the
      # original method proc as a first argument followed by the original
      # method arguments (before +DbMod+ has made any attempt to validate
      # them!). It is expected to yield to the original proc at some point,
      # although it is allowed to do whatever it wants with the results
      # before returning them.
      #
      # @param mod [Module] the module where the method has been defined
      # @param name [Symbol] the method name
      # @param wrapper [Proc] a function which will be used to wrap the
      #   original method definition
      def self.extend_method(mod, name, wrapper)
        mod.instance_eval do
          wrapped = instance_method(name)

          define_method(name, lambda do |*args|
            wrapper.call wrapped.bind(self), *args
          end)
        end
      end
    end
  end
end

require_relative 'configuration/configurable_method'
