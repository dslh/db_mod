require_relative 'configuration/method_configuration'

module DbMod
  module Statements
    # Allows modules to declare a block of default settings that
    # will be applied to all methods declared in the module using
    # +def_prepared+ or +def_statement+. These default settings will
    # be used for all methods in the module where no overriding
    # settings are declared with the method definition.
    #
    #  module JsonAccessors
    #    include DbMod
    #
    #    default_method_settings do
    #      single(:row).as(:json).returning { |json| do_whatever(json) }
    #    end
    #
    #    # Normal access to instance scope for `returning`
    #    def do_whatever(thing)
    #      # ...
    #    end
    #
    #    def_prepared(:foo, 'SELECT * FROM foo WHERE id = $1')
    #
    #    def_prepared(:bar, 'SELECT * FROM bar WHERE id = $1')
    #
    #    # Overrides can be provided for any setting
    #    def_prepared(:all_foos, 'SELECT * FROM foo') { single(false) }
    #    def_prepared(:csv_foo, 'SELECT * FROM foo WHERE id = $1') do
    #      as(:csv)
    #    end
    #  end
    #
    # Existing {Configuration::MethodConfiguration} objects may be
    # passed directly to +default_method_settings+ instead of supplying
    # a block. This allows configurations to be reused between modules.
    #
    #  SETTINGS = DbMod::Statements::Configuration::MethodConfiguration.new do
    #    single(:row).as(:json)
    #  end
    #
    #  module A
    #    include DbMod
    #
    #    default_method_settings(SETTINGS)
    #
    #    # ...
    #
    #  end
    #
    #  module B
    #    include A
    #
    #    # This also works
    #    default_method_settings(A.default_method_settings)
    #
    #    # ...
    #
    #  end
    module DefaultMethodSettings
      # Defines a module-specific +default_method_settings+ function
      # for a module that has just had {DbMod} included.
      #
      # @param mod [Module] module including {DbMod}
      # @see DbMod.included
      def self.setup(mod)
        class << mod
          define_method(:default_method_settings) do |*args, &block|
            unless args.any? || block
              return @default_method_settings ||=
                Configuration::MethodConfiguration.new
            end

            @default_method_settings =
              Configuration::MethodConfiguration.new(*args, &block)
          end
        end
      end
    end
  end
end
