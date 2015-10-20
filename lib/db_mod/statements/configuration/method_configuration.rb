require_relative 'as'
require_relative 'defaults'
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
        # @param block [proc] block containing method configuration declaration
        # @yield executes the block using +self+ as scope
        def initialize(&block)
          @settings = {}
          instance_exec(&block) if block_given?
        end

        # Extend the method by converting results into a given
        # format, using one of the coercion methods defined
        # under {DbMod::Statements::Configuration::As}.
        #
        # @param type [:csv,:json] output format for the method
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

        # Return all given settings in a hash.
        # @return [Hash]
        def to_hash
          @settings
        end

        private

        # Guard method which asserts that a configuration method
        # may not be called more than once, or else raises
        # {DbMod::Exceptions::BadMethodConfiguration}.
        #
        # @param setting [Symbol] setting name
        # @param value [Object] setting value
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
        def one_of!(value, allowed)
          return if allowed.key? value

          fail ArgumentError, "#{value} not in #{allowed.keys.join ', '}"
        end
      end
    end
  end
end
