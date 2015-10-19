## `db_mod`

Database enabled modules for ruby.

[![GitHub version](https://badge.fury.io/gh/dslh%2Fdb_mod.svg)](https://github.com/dslh/db_mod)
[![Travis CI](https://img.shields.io/travis/dslh/db_mod/master.svg)](https://travis-ci.org/dslh/db_mod)
[![Gem downloads](https://img.shields.io/gem/dt/db_mod.svg)](https://rubygems.org/gems/db_mod)

[Rubydoc.info documentation](http://www.rubydoc.info/gems/db_mod)

## Description

The `db_mod` gem is a simple framework that helps you organise your
database access functions into modular libraries that can be included
in your projects to give them selective access to facets of your data.

For the moment `db_mod` only supports PostgreSQL databases via the
`pg` gem. This gem is still in the early stages of development and no
guarantees will be made about backwards compatibility until v0.1.0.

Issues, feature or pull requests, comments and feedback all welcomed.

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

#### Module instances: `DbMod.create`

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

#### The connection object: `@conn`

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

### Declaring SQL statements

#### Prepared statement methods: `DbMod.def_prepared`

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

#### Saved statement methods: `DbMod.def_statement`

`def_statement` works in just the same way as `def_prepared`, except that
the SQL queries are saved in memory rather than being sent to the database
at connection time. This is useful for queries that will only be run once
or twice during a program's execution.

#### Configuring defined statements

`db_mod` contains a simple framework for extending these statement methods
and prepared methods with additional result processing. A block can be
passed to +def_prepared+ and +def_statement+ definitions, where a basic
DSL is made available for additional method configuration.

##### JSON and CSV formatting

Statement and prepared methods can be configured on declaration by using
`as(:csv)` and `as(:json)`, which will convert the result set to a string
formatted as either a CSV document or an array of JSON objects, respectively.

```ruby
module Reports
  include DbMod

  def_prepared(:foo, 'SELECT a, b FROM foo WHERE bar_id = $id') { as(:csv) }
  def_statement(:bar, 'SElECT c, d FROM bar WHERE foo_id = $1') { as(:json) }
end

include Reports
db_connect db: 'testdb'

foo(id: 1) # => "a,b\n1,2\n3,4\n..."
bar(2) # => '[{"c":"5","d":"6"},...]'
```

##### Queries returning one row, column or value

To save a lot of repetetive unboxing of query results, methods that return
only one row, or rows with only one column, or only one row with a single
value, can be marked as such using the `single` extension.

```ruby
module Getters
  include DbMod

  def_prepared(:user, 'SELECT * FROM user WHERE id = $1') { single(:row) }
  def_prepared(:name, 'SELECT name FROM user WHERE id = $1') { single(:value) }
  def_statement(:ids, 'SELECT id FROM user') { single(:column) }
end

# ...

user(1) # => { "id" => "1", "name" => "username" }
name(1) # => "username"
ids # => ['1', '2', '3', ...]
```

When no results are returned, `:column` returns `[]` while  `:row` and
`:value` will return `nil`. To raise an exception instead of returning
`nil`, use `:row!` and `:value!` instead.

```ruby
def_statement(:a, 'SELECT 1 WHERE true = false') { single(:value) }
def_statement(:b, 'SELECT 1 WHERE true = false') { single(:value!) }

a # => nil
b # => fail
```

##### Default parameter values

Arbitrary default parameter values can be supplied using `defaults`.

For methods with named parameters:

```ruby
def_statement(:a, 'SELECT * FROM foo WHERE id = $id AND y > $min') do
  defaults min: 10
end

# ...

a(id: 1) # === a(id: 1, min: 10)
```

For methods with fixed parameters:

```ruby
def_statement(:a, %(
  SELECT *
    FROM foo
   WHERE x = $1
     AND y < $2
     AND z > $3
)) { defaults 4, 5, 6 }

# ...

a(1) # === a(1, 5, 6)
```
