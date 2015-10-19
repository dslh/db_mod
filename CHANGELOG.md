0.0.5
=====
Breaking changes. Any statement or prepared methods with additional configuration
should have such configuration declared in a block, rather than a method chain
(although methods can be chained inside the method block). E.g.

```ruby
def_statement(:a, 'SELECT * FROM foo WHERE id = $1').single(:row).as(:json)

# ... becomes ...

def_statement(:a, 'SELECT * FROM foo WHERE id = $1') { single(:row).as(:json) }
```

* +def_statement+ and +def_prepared+ method configuration must now be supplied
  as a block. This allows method configuration to be collected ahead of
  method definition, and hence a bit more smarts during the method declaration
  process - [@dslh](https://github.com/dslh).
* `defaults` - default parameter values for statement and prepared methods - [@dslh](https://github.com/dslh).
* `single(:row/:column).as(:json)` now works - [@dslh](https://github.com/dslh).

0.0.4 (2015-10-15)
==================

* Adds `def_prepared/statement.single(:value/:row/:column)` - [@dslh](https://github.com/dslh).
* Adds `.as(:json)` to go with `.as(:csv)` - [@dslh](https://github.com/dslh).

0.0.3 (2015-10-13)
==================

* Configurable method framework. Adds `def_prepared/statement.as(:csv)` - [@dslh](https://github.com/dslh).

0.0.2 (2015-10-12)
==================

* Adds `def_statement` to compliment `def_prepared` - [@dslh](https://github.com/dslh).

0.0.1 (2015-10-11)
==================

* Initial release - [@dslh](https://github.com/dslh).
