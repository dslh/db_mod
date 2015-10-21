require 'pg'

require_relative 'db_mod/create'
require_relative 'db_mod/exceptions'
require_relative 'db_mod/statements'
require_relative 'db_mod/transaction'
require_relative 'db_mod/version'

# This is the foundation module for enabling db_mod
# support in an application. Including this module
# will give your class or object the protected methods
# {#db_connect} and {#conn=}, allowing the connection
# to be set or created, as well as the methods {#conn},
# {#query}, {#transaction}, and +def_prepared+.
module DbMod
  include Transaction

  # When a module includes {DbMod}, we define some
  # class-level functions specific to the module.
  # This technique is required where it is not
  # sufficient to simply define a module method
  # on {DbMod} itself due to metaprogramming techniques
  # requiring access to the module as +self+.
  #
  # See {DbMod::Create.setup}
  # and {DbMod::Statements.setup}
  #
  # @param mod [Module] module which has had {DbMod} included
  # @see http://ruby-doc.org/core-2.2.3/Module.html#method-i-included
  #   Module#included
  def self.included(mod)
    DbMod::Create.setup(mod)
    DbMod::Statements.setup(mod)

    # Ensure that these definitions cascade when
    # submodules are included in subsequent submodules.
    class << mod
      define_method(:included) { |sub_mod| DbMod.included(sub_mod) }
    end
  end

  protected

  # Database object to be used for all database
  # interactions in this module.
  # Use {#db_connect} to initialize the object.
  #
  # @return [PGconn] for now, only PostgreSQL is supported
  attr_reader :conn

  # A custom-built connection object
  # may be supplied in place of calling {#db_connect}.
  # Be aware in this case that certain responsibilities
  # of {#db_connect} may need to be taken care of manually,
  # in particular preparing SQL statements.
  #
  # @param value [PGconn] for now, only PostgreSQL is supported.
  attr_writer :conn

  # Shorthand for +conn.query+
  #
  # @param sql [String] SQL query to execute
  # @return [Object] SQL result set
  def query(sql)
    unless @conn
      fail DbMod::Exceptions::ConnectionNotSet, 'db_connect not called'
    end
    conn.query(sql)
  end

  # Create a new database connection to be used
  # for all database interactions in this module.
  #
  # @param options [Hash] database connection options
  # @option options [String] :db
  #   the name of the database to connect to
  # @option options [String] :host
  #   the host server for the database. If not supplied a local
  #   posix socket connection will be attempted.
  # @option options [Fixnum] :port
  #   port number the database server is listening on. Default is 5432.
  # @option options [String] :user
  #   username for database authentication. If not supplied the
  #   name of the user running the script will be used (i.e. ENV['USER'])
  # @option options [String] :pass
  #   password for database authentication. If not supplied then
  #   trusted authentication will be attempted.
  def db_connect(options = {})
    db_defaults! options
    @conn = db_connect! options
    self.class.prepare_all_statements(@conn)
  end

  private

  # Load any missing options from defaults
  #
  # @param options [Hash] see {#db_connect}
  # @see #db_connect
  def db_defaults!(options)
    fail ArgumentError, 'database name :db not supplied' unless options[:db]
    options[:port] ||= 5432
    options[:user] ||= ENV['USER']
    options[:pass] ||= 'trusted?'
  end

  # Create the database object itself.
  #
  # @param options [Hash] see {#db_connect}
  # @return [PGconn] a new database connection
  def db_connect!(options)
    PGconn.connect(
      options[:host],
      options[:port],
      '',
      '',
      options[:db],
      options[:user],
      options[:pass]
    )
  end
end
