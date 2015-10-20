module DbMod
  # Provides the +create+ function which
  # is added to all modules which include {DbMod}.
  # This function creates an object which exposes
  # the functions defined in the module, allowing
  # them to be used without namespace pollution.
  #
  # The function may be used in two forms. It may
  # be called with an options hash, in which case
  # {DbMod#db_connect} will be used to create a
  # new connection object. Alternatively an
  # existing connection object may be passed,
  # which will be used for all database queries.
  module Create
    # Defines a module-specific +create+ function
    # for a module that has just had {DbMod}
    # included.
    #
    # @param mod [Module] the module where {DbMod}
    #   has been included
    # @see DbMod.included
    def self.setup(mod)
      mod.class.instance_eval do
        define_method(:create) do |options = {}|
          @instantiable_class ||= Create.instantiable_class(self)

          @instantiable_class.new(options)
        end
      end
    end

    private

    # Creates a class which inherits from the given module
    # and can be instantiated with either a connection object
    # or some connection options.
    #
    # @param mod [Module]
    def self.instantiable_class(mod)
      Class.new do
        include mod

        define_method(:initialize) do |options|
          if options.is_a? PGconn
            self.conn = options
          else
            db_connect options
          end
        end
      end
    end
  end
end
