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
      # statement method or prepared method with additional result processing.
      # A method should be provided, which accepts an SQL result set and
      # returns some transformation of the results. The original method
      # declaration will be replaced, so that the original method definition
      # is called and the results are passed through this given method.
      #
      # @param mod [Module] the module where the method has been defined
      # @param name [Symbol] the method name
      # @param wrapper [#call]
      #   a function that processes the SQL results in some way
      def self.process_method_results(mod, name, wrapper)
        mod.instance_eval do
          wrapped = instance_method(name)

          define_method(name, lambda do |*args|
            wrapper.call wrapped.bind(self).call(*args)
          end)
        end
      end
    end
  end
end

require_relative 'configuration/configurable_method'
