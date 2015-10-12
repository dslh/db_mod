## `db_mod`

Database enabled modules for ruby.

## Description

The `db_mod` gem is a simple framework that helps you organise your
database access functions into modular libraries that can be included
in your projects to give them selective access to facets of your data.

For the moment `db_mod` only supports PostgreSQL databases via the
`pg` gem.

## Usage

### The database connection

At its most basic, `db_mod` provides `db_connect`, `query`, and
`transaction`:

```ruby
require 'db_mod'

module MyFunctions
  include DbMod

  def get_stuff
    query 'SELECT * FROM stuff'
  end

  def do_complicated_thing(input)
    transaction do # calls BEGIN
      query 'INSERT ...'
      query 'UPDATE ...'
      query 'DELETE ...'

      output = query 'SELECT ...'
      fail if output.empty? # calls ROLLBACK
    end # calls COMMIT
  end
end

include MyFunctions

db_connect(
  db: 'mydb',
  host: 'localhost', # defaults to local socket
  port: 5432,        # this is the default
  user: 'myuser',    # default is ENV['USER']
  pass: 'password'   # attempts trusted connection by default
)

get_stuff.each do |thing|
  thing['id'] # => '1'
  # ...
end
```

#### `create`: Module instances

Each module also comes with its own `create` function,
which instantiates an object exposing all of the module's functions.

```ruby
# Standard connection options can be used.
# db_connect will be called.
db = MyFunctions.create db: 'mydb'

# Or an existing connection object can be passed
db = MyFunctions.create PGconn.connect # ...

db.get_stuff
```

#### `@conn`: The connection object

The connection created by `db_connect` or `create` will be stored
in the instance variable `@conn`. This instance variable may be
set explicitly instead of calling `db_connect`, allowing arbitrary
sharing of database connections between modules and objects.
See notes below on using this technique with `def_prepared`.

### Module heirarchies

By including multiple modules into the same class or object, they
will all use the same connection object supplied by `db_connect`.
This connection object is stored in the instance variable `@conn`
and can be supplied manually:

```ruby
module DbAccess
  # includes DbMod and defines do_things
  include Db::Things

  # includes DbMod and defines do_stuff
  include Db::Stuff

  def things_n_stuff
    transaction do
      do_things
      do_stuff
    end
  end
end

db = DbAccess.create db: 'mydb'
db.things_n_stuff
```

### `def_prepared`: Declaring SQL statements

Modules which include `DbMod` can declare prepared statements
using the module function `def_prepared`. These statements will
be prepared on the connection when `db_connect` is called.
A method will be defined in the module with the same name as
the prepared statement, provided as a convenience for executing
the statement:

```ruby
module Db
  module Things
    # Statements can use named parameters:
    def_prepared :foo, <<-SQL
      SELECT *
        FROM foo
       WHERE id = $id
         AND b > $minimum_value
         AND c > $minimum_value
    SQL
  end

  module Stuff
    # Indexed parameters also work:
    def_prepared :bar, <<-SQL
      INSERT INTO bar
        (a, b, c)
      VALUES
        ($1, $2, $1)
    SQL
  end

  module ComplicatedStuff
    # Statements on included modules will also
    # be executed when db_connect is called.
    include Things
    include Stuff

    def complicated_thing!(id, min)
      transaction do
        foo(id: id, minimum_value: min).each do |thing|
          bar(thing['a'], thing['b'])
        end
      end
    end
  end
end

include Db::ComplicatedStuff
db_connect db: 'mydb'

complicated_thing!(1, 2)
```

Note that if an existing connection is supplied to `create` or `@conn`
then declared statements will not be automatically prepared. In this
case the module function `prepare_all_statements(conn)` can be used
to prepare all statements declared in the module or any included
modules on the given connection.

```ruby
db = Db::ComplicatedStuff.create my_conn
Db::ComplicatedStuff.prepare_all_statements my_conn
```
