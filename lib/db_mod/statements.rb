require_relative 'statements/configurable_method'
require_relative 'statements/statement'
require_relative 'statements/prepared'

module DbMod
  # Functions allowing {DbMod} modules to declare
  # SQL statements that can be called later via
  # automatically declared instance methods.
  #
  # See {DbMod::Statements::Statement} for details on +def_statement+
  # and {DbMod::Statements::Prepared} for details on +def_prepared+.
  module Statements
    # Called when a module includes {DbMod},
    # defines module-level +def_statement+ and +def_prepared+ dsl methods.
    def self.setup(mod)
      DbMod::Statements::Prepared.setup(mod)
      DbMod::Statements::Statement.setup(mod)
    end

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
    def self.configurable_method(mod, name, definition)
      mod.instance_eval { define_method(name, definition) }

      ConfigurableMethod.new(mod, name)
    end

    # Used by {ConfigurableMethod} (and associated code) to wrap a defined
    # statement method or prepared method with additional parameter or result
    # processing. A wrapper method definition should be provided, which will
    # be called in place of the original method. It will be called with the
    # original method proc as a first argument followed by the original
    # method arguments (before +DbMod+ has made any attempt to validate them!).
    # It is expected to yield to the original proc at some point, although it
    # is allowed to do whatever it wants with the results before returning them.
    #
    # @param mod [Module] the module where the method has been defined
    # @param name [Symbol] the method name
    # @param wrapper [Proc] a function which will be used to wrap the
    #   original method definition
    def self.extend_method(mod, name, wrapper)
      mod.instance_eval do
        wrapped = instance_method(name)

        define_method name, ->(*args) { wrapper.call wrapped.bind(self), *args }
      end
    end
  end
end
