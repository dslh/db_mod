require 'pg'
require_relative 'db_mod/exceptions'
require_relative 'db_mod/transaction'
require_relative 'db_mod/create'
require_relative 'db_mod/statements'

# This is the foundation module for enabling db_mod
# support in an application. Including this module
# will give your class or object the protected methods
# {#db_connect} and {#conn=}, allowing the connection
# to be set or created, as well as the methods {#conn},
# {#query}, {#transaction}, and {#def_prepared}.
module DbMod
  include Transaction

  # When a module includes {DbMod}, we define some
  # class-level functions specific to the module.
  def self.included(mod)
    DbMod::Create.setup(mod)
    DbMod::Statements.setup(mod)
  end

  protected

  # Database object to be used for all database
  # interactions in this module.
  # Use {#db_connect} to initialize the object.
  attr_accessor :conn

  # Shorthand for +conn.query+
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
  def db_defaults!(options)
    fail ArgumentError, 'database name :db not supplied' unless options[:db]
    options[:port] ||= 5432
    options[:user] ||= ENV['USER']
    options[:pass] ||= 'trusted?'
  end

  # Create the database object itself.
  #
  # @param options [Hash] see {#db_connect}
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
