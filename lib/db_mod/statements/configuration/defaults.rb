module DbMod
  module Statements
    module Configuration
      # Provides functionality backing the {MethodConfiguration#defaults}
      # setting. Allows certain statement or prepared method parameters to
      # be omitted, supplying default values where necessary:
      #
      #  def_statement(:a, 'SELECT id FROM a WHERE x > $y') { defaults y: 10 }
      #  def_prepared(:b, %(
      #    INSERT INTO b
      #      (p, q, r)
      #    VALUES
      #      ($1, $2, $3)
      #    RETURNING p, q, r
      #  )) { defaults(5, 6).single(:row) }
      #
      #  def_prepared(:c, 'SELECT a FROM b WHERE d = $e AND f > $g') do
      #    # procs may be used
      #    defaults g: ->(args) { args[:e] * 10 }
      #  end
      #
      #  # ...
      #
      #  a    # y => 10
      #  a 11 # y => 11
      #
      #  # defaults filled in from the right
      #  b 1, 2 # => { 'p' => '1', 'q' => '2', 'r' => '6' }
      #
      #  # proc defaults executed when method is called
      #  c e: 2 # === c e: 2, g: 20
      module Defaults
        # Extend a method definition by wrapping it with a proc that will
        # try to fill in any omitted arguments with given defaults.
        #
        # @param definition [Proc] base method definition,
        #   with parameter validation already attached
        # @param params [Hash<Symbol,value>,Array<value>]
        #   see {Configuration.def_configurable}
        # @param defaults [Hash<Symbol,value,Array<value>]
        #   default values, in the same form as they would be provided
        #   to the original method definition except that some values
        #   may be omitted. Defaults may either be constant values, or
        #   a lambda proc may be given, which will be passed the
        #   entirety of the argument list and should return a single
        #   value to be used when none is given
        # @return [Proc] new method definition, or the same one
        #   if no default values have been appended
        def self.extend(definition, params, defaults)
          return definition if defaults.nil?

          if [[], 0].include? params
            fail ArgumentError, 'defaults not allowed for no-args methods'
          end

          if params.is_a? Array
            extend_named_args_method(definition, defaults)
          else
            extend_fixed_args_method(definition, params, defaults)
          end
        end

        private

        # Extend a method with named parameters, providing default
        # argument values for one or more parameters.
        #
        # @param definition [Proc] base method definition,
        #   with parameter validation already attached
        # @param defaults [Hash<Symbol,value>]
        #   see {Defaults.extend}
        # @return [Proc] wrapped method definition
        def self.extend_named_args_method(definition, defaults)
          unless defaults.is_a? Hash
            fail ArgumentError, 'hash expected for defaults'
          end

          lambda do |*args|
            Defaults.use_named_defaults(self, args, defaults)
            instance_exec(*args, &definition)
          end
        end

        # Fill in any missing parameter arguments using default
        # values where available.
        #
        # @param scope [Object] scope to be used for executing
        #   default values that are lambda procedures. Should
        #   be the instance object where the method has been
        #   defined.
        # @param args [[Hash<Symbol,value>]] method arguments
        #   before processing and validation
        # @param defaults [Hash<Symbol,value>]
        #   default parameter values
        # @see Defaults.extend_named_args_method
        def self.use_named_defaults(scope, args, defaults)
          # Special case when no args given.
          args << {} if args.empty?

          # If the args are weird, expect normal parameter validation
          # to pick it up.
          return args unless args.last.is_a? Hash

          defaults.each do |arg, value|
            next if args.last.key? arg

            args.last[arg] = value! value, scope, args.last
          end
        end

        # Execute the default 'value' if it is a +Proc+,
        # or just return it.
        #
        # @param value [Proc,Object] default value as specified
        #   by {MethodConfiguration#defaults}
        # @param scope [Object] scope to be used for executing
        #   default values that are lambda procedures. Should
        #   be the instance object where the method has been
        #   defined.
        # @param args [Hash,Array] fixed or named argument
        #   list, to be passed to the 'value' if it is a proc
        # @return [Object] value to be passed to the parametered
        #   database query
        def self.value!(value, scope, args)
          if value.is_a? Proc
            scope.instance_exec(args, &value)
          else
            value
          end
        end

        # Extend a method with numbered parameters, providing
        # default argument values for one or more parameters.
        # Defaults will be applied, in the same left-to-right
        # order, but at the right-hand side of the parameter
        # list, as with normal method default arguments.
        #
        # @param definition [Proc] base method definition,
        #   with parameter validation already attached
        # @param arity [Fixnum] number of arguments expected
        #   by the base method definition
        # @param defaults [Array]
        #   default parameter values
        # @return [Proc] wrapped method definition
        def self.extend_fixed_args_method(definition, arity, defaults)
          fail ArgumentError, 'too many defaults' if defaults.size > arity

          unless defaults.is_a? Array
            fail ArgumentError, 'array expected for defaults'
          end

          arity = (arity - defaults.size)..arity
          fail ArgumentError, 'too many defaults' if arity.min < 0

          lambda do |*args|
            Defaults.use_fixed_defaults(self, args, defaults, arity)
            instance_exec(*args, &definition)
          end
        end

        # Fill in any missing parameter arguments using default values
        # where available.
        #
        # @param scope [Object] scope to be used for executing
        #   default values that are lambda procedures. Should
        #   be the instance object where the method has been
        #   defined.
        # @param args [Array] method arguments
        #   before processing and validation
        # @param defaults [Array] default parameter values
        # @param arity [Range<Fixnum>] number of arguments
        #   expected by the base method definition
        # @raise [ArgumentError] if there are not enough or too many args
        # @see Defaults.extend_fixed_args_method
        def self.use_fixed_defaults(scope, args, defaults, arity)
          unless arity.include? args.count
            fail ArgumentError, "#{args.count} given, (#{arity}) expected"
          end

          defaults[args.size - arity.min...defaults.size].each do |arg|
            args << value!(arg, scope, args)
          end
        end
      end
    end
  end
end
