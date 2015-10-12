require 'spec_helper'

describe DbMod::Statements::Prepared do
  subject do
    Module.new do
      include DbMod

      def_prepared :one, <<-SQL
        SELECT *
          FROM foo
         WHERE a = $1 AND b = $2 AND c = $1
      SQL

      def_prepared :two, <<-SQL
        SELECT *
          FROM foo
         WHERE a = $a AND b = $b AND c = $a
      SQL
    end
  end

  before do
    @conn = instance_double 'PGconn'
    allow(PGconn).to receive(:connect).and_return(@conn)
    allow(@conn).to receive(:prepare)
  end

  it 'adds statements when the connection is created' do
    expect(@conn).to receive(:prepare) do |name, sql|
      expect(%w(one two)).to include name
      expect(sql.split(/\s+/m).join(' ').strip).to eq(
        'SELECT * FROM foo WHERE a = $1 AND b = $2 AND c = $1'
      )
    end

    subject.create db: 'testdb'
  end

  it 'executes statements with numbered params' do
    db = subject.create db: 'testdb'

    expect(@conn).to receive(:exec_prepared).with('one', [1, 'two'])
    db.one(1, 'two')

    expect { db.one 'too', 'many', 'args' }.to raise_exception ArgumentError
  end

  it 'executes statements with named params' do
    db = subject.create db: 'testdb'

    expect(@conn).to receive(:exec_prepared).with('two', [2, 'three'])
    db.two(b: 'three', a: 2)

    expect { db.two bad: 'arg', b: 1, a: 1 }.to raise_exception ArgumentError
    expect { db.two b: 'a missing' }.to raise_exception ArgumentError
    expect { db.two 1, 2 }.to raise_exception ArgumentError
    expect { db.two 1 }.to raise_exception ArgumentError
  end

  it 'prepares and exposes inherited prepared statements' do
    mod = subject
    sub_module = Module.new do
      include mod

      def_prepared :three, <<-SQL
        SELECT *
          FROM foo
         WHERE a = $1 OR b = $2 OR c = $1
      SQL
    end

    expect(@conn).to receive(:prepare).exactly(3).times do |name, _|
      expect(%w(one two three)).to include name
    end

    sub_module.create db: 'testdb'
  end

  it 'does not allow mixed parameter types' do
    expect do
      Module.new do
        include DbMod

        def_prepared :numbers_and_names, <<-SQL
          SELECT *
            FROM foo
           WHERE this = $1 AND wont = $work
        SQL
      end
    end.to raise_exception ArgumentError
  end

  it 'allows no parameters' do
    expect do
      mod = Module.new do
        include DbMod

        def_prepared :no_params, 'SELECT 1'
      end

      expect(@conn).to receive(:prepare).with('no_params', 'SELECT 1')
      expect(@conn).to receive(:exec_prepared).with('no_params')

      db = mod.create(db: 'testdb')
      db.no_params

      expect { db.no_params(1) }.to raise_exception ArgumentError
    end.not_to raise_exception
  end

  it 'handles complicated parameter usage' do
    mod = Module.new do
      include DbMod

      def_prepared(
        :params_test,
        'INSERT INTO foo (a,b,c,d) VALUES ($a-1,$b::integer,$c*2,$b)'
      )
    end

    expect(@conn).to receive(:prepare).with(
      'params_test',
      'INSERT INTO foo (a,b,c,d) VALUES ($1-1,$2::integer,$3*2,$2)'
    )
    db = mod.create(db: 'testdb')

    expect(@conn).to receive(:exec_prepared).with(
      'params_test',
      [1, 2, 3]
    )
    db.params_test(a: 1, b: 2, c: 3)
  end

  it 'does not allow invalid parameters' do
    %w(CAPITALS numb3rs_and_l3tt3rs).each do |param|
      expect do
        Module.new do
          include DbMod

          def_prepared :bad_params, %(
            SELECT * FROM foo where bad = $#{param}
          )
        end
      end.to raise_exception ArgumentError
    end
  end

  it 'does not allow duplicate statement names' do
    mod = subject
    sub_module = Module.new do
      include mod

      def_prepared :one, <<-SQL
        SELECT not FROM gonna WHERE work = $1
      SQL
    end

    expect { sub_module.create db: 'testdb' }.to raise_exception(
      DbMod::Exceptions::DuplicateStatementName
    )
  end

  it 'validates numbered arguments' do
    [
      'a = $1 AND b = $2 AND c = $2 AND c = $4',
      'a = $2 AND b = $2 AND c = $3',
      'a = $1 AND b = $2 AND c = $4'
    ].each do |params|
      expect do
        Module.new do
          include DbMod

          def_prepared :bad_params, "SELECT * FROM foo WHERE #{params}"
        end
      end.to raise_exception ArgumentError
    end
  end
end
