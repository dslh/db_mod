module DbMod
  module Statements
    # Provides additional functionality to statement and
    # prepared methods, allowing additional processing of
    # arguments and results using the dsl extensions
    # exposed via {MethodConfiguration}.
    module Configuration
      # Used by submodules to when defining a method as declared by
      # +def_statement+ or +def_prepared+. Wraps the defined method
      # so that it may be extended with additional argument and
      # result processing.
      #
      # @param mod [Module] the module where the method has been declared
      # @param name [Symbol] the name of the module that has been defined
      # @param definition [Proc] method definition, the base function which
      #   will perform database interaction and return an SQL result object
      # @param params [Array<Symbol>,Fixnum] declares the parameters that
      #   the method will accept. Can either be an array of named parameters
      #   or a integer giving the arity of the function. +[]+ may also be
      #   given to denote a no-argument method.
      # @yield dsl block may be passed, which will be evaluated using a
      #   {MethodConfiguration} object as scope
      def self.def_configurable(mod, name, definition, params = 0, &block)
        config =
          if block_given?
            MethodConfiguration.new(mod.default_method_settings, &block)
          else
            mod.default_method_settings
          end

        config &&= config.to_hash

        definition = attach_result_processors(definition, config) if config
        definition = attach_param_processor(definition, params, config)

        mod.instance_eval { define_method(name, definition) }
      end

      private

      # Attaches any required parameter processing and validation to
      # the method definition by wrapping it in a further proc as required.
      #
      # @param definition [Proc] base method definition
      # @param params see {Configuration.def_configurable}
      # @param config [MethodConfiguration] for default values
      # @return [Proc] a new wrapper for +definition+
      def self.attach_param_processor(definition, params, config)
        wrapped =
          if params.is_a?(Array) && !params.empty?
            define_named_args_method(definition, params)

          elsif params.is_a?(Fixnum) && params > 0
            define_fixed_args_method(definition, params)

          else
            ->() { instance_exec(&definition) }
          end

        return wrapped unless config
        Defaults.extend(wrapped, params, config[:defaults])
      end

      # Wrap the given definition in a procedure that will validate any
      # passed arguments, and transform them into an array that can be
      # passed directly to +PGconn.exec_params+ or +PGconn.exec_prepared+.
      #
      # @param definition [Proc] base method definition
      # @param params [Array<Symbol>] list of method parameter names
      # @return [Proc] new method definition
      def self.define_named_args_method(definition, params)
        lambda do |*args|
          args = Parameters.valid_named_args! params, args
          instance_exec(*args, &definition)
        end
      end

      # Wrap the given definition in a procedure that will validate that
      # the correct number of arguments has been passed, before passing them
      # on to the original method definition.
      #
      # @param definition [Proc] base method definition
      # @param arity [Fixnum] expected number of arguments
      # @return [Proc] new method definition
      def self.define_fixed_args_method(definition, arity)
        lambda do |*args|
          Parameters.valid_fixed_args!(arity, args)
          instance_exec(*args, &definition)
        end
      end

      # Attaches any required result processing to the method definition,
      # as may have been defined in a block passed to either of +def_statement+
      # or +def_prepared+. This method is called before
      # {Configuration.attach_param_processor}, so that the method definition
      # can be wrapped by the parameter processor. In this way processors
      # attached here are assured access to method parameters after any
      # initial processing and validation has taken place.
      #
      # @param definition [Proc] base method definition
      # @param config [MethodConfiguration] configuration declared at
      #   method definition time
      def self.attach_result_processors(definition, config)
        definition = Single.extend(definition, config)
        definition = As.extend(definition, config)
        definition = Returning.extend(definition, config)

        definition
      end

      # Attach a processor to the chain of result processors for a method.
      # The pattern here is something similar to rack's middleware.
      # A result processor is constructed with a method definition, and
      # then acts as a replacement for the method, responding to +#call+.
      # Subclasses must implement a +process+ method, which should accept
      # an SQL result set (or possibly, the result of other upstream
      # processing), perform some transform on it and return the result.
      #
      # @param definition [Proc] base method definition
      # @param processor [#call] result processor
      def self.attach_result_processor(definition, processor)
        if processor.is_a? Proc
          lambda do |*args|
            instance_exec(instance_exec(*args, &definition), &processor)
          end
        else
          ->(*args) { processor.call instance_exec(*args, &definition) }
        end
      end
    end
  end
end

require_relative 'configuration/method_configuration'
