require_relative 'as'
require_relative 'defaults'
require_relative 'returning'
require_relative 'single'

module DbMod
  module Statements
    module Configuration
      # Collects settings given at time of definition for statement
      # and prepared methods. If a block is passed to +def_statement+
      # or +def_prepared+ it will be evaluated using an instance of
      # this class, allowing methods such as {#as} or {#single} to
      # be used to shape the behaviour of the defined method.
      class MethodConfiguration
        # Creates a new configuration object to be used as the scope for
        # blocks passed to +def_statement+ and +def_prepared+ declarations.
        #
        # @param args [*] one or more +MethodConfiguration+ objects or hashes
        #   from which existing settings will be merged
        # @param block [proc] block containing method configuration declaration
        # @yield executes the block using +self+ as scope
        def initialize(*args, &block)
          @settings = {}
          instance_exec(&block) if block_given?

          merge_settings(args)
        end

        # Extend the method by converting results into a given
        # format, using one of the coercion methods defined
        # under {DbMod::Statements::Configuration::As}.
        #
        # @param type [:csv,:json] output format for the method
        #   may be set to +nil+ or +false+ to un-set any
        #   inherited setting
        # @return [self]
        def as(type)
          one_of! type, Configuration::As::COERCERS
          set_once! :as, type

          self
        end

        # Extend the method by extracting a singular part of
        # the result set, for queries expected to only return
        # one row, one column, or one row with a single value.
        # See {DbMod::Statements::Configuration::Single} for
        # more details.
        #
        # @param type [Symbol] see {Configuration::Single::COERCERS}
        #   may be set to +nil+ or +false+ to un-set any
        #   inherited setting
        # @return [self]
        def single(type)
          one_of! type, Configuration::Single::COERCERS
          set_once! :single, type

          self
        end

        # Declares default values for method parameters.
        # For methods with named parameters, a hash of argument
        # names and default values should be provided.
        # For methods with indexed parameters, an array of 1..n
        # default values should be provided, where n is the
        # method's arity. In this case default values will be
        # applied to the right-hand side of the argument list,
        # as with normal parameter default rules.
        #
        # In place of a fixed default value, a lambda +Proc+
        # may be supplied. In this case the proc will be executed,
        # given the partially constructed argument list/hash and
        # scoped against the instance variable where the prepared
        # or statement method is defined. It should return a single
        # value to be used for that particular execution of the
        # method.
        #
        # @param defaults [Hash<Symbol,value>,Array<value>]
        #   default parameter values
        # @return [self]
        def defaults(*defaults)
          if defaults.size == 1 && defaults.first.is_a?(Hash)
            defaults = defaults.first
          elsif defaults.last.is_a? Hash
            fail ArgumentError, 'mixed default declaration not allowed'
          end

          set_once! :defaults, defaults

          self
        end

        # Declares a block that will be used to transform or replace
        # the SQL result set before it is returned from the defined
        # method. The block should accept a single parameter and can
        # return pretty much whatever it wants.
        #
        # The block will be applied after any transforms specified by
        # {#as} or {#single} have already been applied.
        #
        # @param block [Proc] block to be executed on the method's result set
        # @return [self]
        def returning(&block)
          fail ArgumentError, 'block required' unless block_given?

          set_once! :returning, block

          self
        end

        # Return all given settings in a hash.
        # @return [Hash]
        def to_hash
          @settings
        end

        private

        # Merge settings from constructor arguments. Allowed arguments
        # are hashes, other {MethodConfiguration} objects, or procs that
        # will be executed with a {MethodConfiguration} object as the
        # scope.
        #
        # @param args [Array] array of objects containing method
        #   configuration settings
        # @return [Hash] == `@settings`
        # @raise [ArgumentError] if any args are invalid (see {#arg_to_hash})
        def merge_settings(args)
          inherited_settings = {}
          args.each do |arg|
            inherited_settings.merge! arg_to_hash arg
          end

          @settings = inherited_settings.merge @settings
        end

        # Convert a single constructor argument into a hash of settings
        # that may be merged into this object's settings hash.
        #
        # @param arg [Object] see {#merge_settings}
        # @return [Hash] a hash of settings derived from the object
        # @raise [ArgumentError] if an unexpected argement is encountered
        # @see #merge_settings
        def arg_to_hash(arg)
          return arg if arg.is_a? Hash
          return arg.to_hash if arg.is_a? MethodConfiguration
          return MethodConfiguration.new(&arg).to_hash if arg.is_a? Proc

          fail ArgumentError, "unknown method setting #{arg.inspect}"
        end

        # Guard method which asserts that a configuration method
        # may not be called more than once, or else raises
        # {DbMod::Exceptions::BadMethodConfiguration}.
        #
        # @param setting [Symbol] setting name
        # @param value [Object] setting value
        # @raise [Exceptions::BadMethodConfiguration] if the settings has
        #   already been set
        def set_once!(setting, value)
          if @settings.key? setting
            fail Exceptions::BadMethodConfiguration, "#{setting} already called"
          end

          @settings[setting] = value
        end

        # Guard method which asserts that a configuration setting
        # is one of the allowed values in the given hash.
        #
        # @param value [key] configuration setting
        # @param allowed [Hash] set of allowed configuration settings
        # @raise [ArgumentError] if the value is not allowed
        def one_of!(value, allowed)
          return if allowed.key? value

          fail ArgumentError, "#{value} not in #{allowed.keys.join ', '}"
        end
      end
    end
  end
end
