require 'spec_helper'

describe DbMod::Statements::Statement do
  subject do
    Module.new do
      include DbMod

      def_statement(
        :one,
        'SELECT * FROM foo WHERE a = $1 AND b = $2 AND c = $1'
      )

      def_statement(
        :two,
        'SELECT * FROM foo WHERE a = $a AND b = $b AND c = $a'
      )
    end.create db: 'testdb'
  end

  before do
    @conn = instance_double 'PGconn'
    allow(PGconn).to receive(:connect).and_return(@conn)
  end

  it 'executes statements with numbered params' do
    expect(@conn).to receive(:exec_params).with(
      'SELECT * FROM foo WHERE a = $1 AND b = $2 AND c = $1',
      [1, 'two']
    )
    subject.one(1, 'two')

    expect { subject.one 'not enough args' }.to raise_exception ArgumentError

    expect do
      subject.one('too', 'many', 'args')
    end.to raise_exception ArgumentError
  end

  it 'executes statements with named params' do
    expect(@conn).to receive(:exec_params).with(
      'SELECT * FROM foo WHERE a = $1 AND b = $2 AND c = $1',
      [1, 'two']
    )
    subject.two(a: 1, b: 'two')

    expect do
      subject.two bad: 'arg', b: 1, a: 1
    end.to raise_exception ArgumentError
    expect { subject.two b: 'a missing' }.to raise_exception ArgumentError
    expect { subject.two 1, 2 }.to raise_exception ArgumentError
    expect { subject.two 1 }.to raise_exception ArgumentError
  end

  it 'allows statements with no parameters' do
    expect do
      mod = Module.new do
        include DbMod

        def_statement :no_params, 'SELECT 1'
      end

      expect(@conn).to receive(:query).with('SELECT 1')
      db = mod.create db: 'testdb'

      expect { db.no_params }.not_to raise_exception
      expect { db.no_params(1) }.to raise_exception ArgumentError
    end.not_to raise_exception
  end

  it 'does not allow mixed parameter types' do
    expect do
      Module.new do
        include DbMod

        def_statement :numbers_and_names, <<-SQL
          SELECT *
            FROM foo
           WHERE this = $1 AND wont = $work
        SQL
      end
    end.to raise_exception ArgumentError
  end

  it 'handles complicated parameter usage' do
    db = Module.new do
      include DbMod

      def_statement(
        :params_test,
        'INSERT INTO foo (a,b,c,d) VALUES ($a-1,$b::integer,$c*2,$b)'
      )
    end.create(db: 'testdb')

    expect(@conn).to receive(:exec_params).with(
      'INSERT INTO foo (a,b,c,d) VALUES ($1-1,$2::integer,$3*2,$2)',
      [1, 2, 3]
    )
    db.params_test(a: 1, b: 2, c: 3)
  end

  it 'does not allow invalid parameters' do
    %w(CAPITALS numb3s_and_l3tt3rs).each do |param|
      expect do
        Module.new do
          include DbMod

          def_statement :bad_params, %(
            SELECT * FROM foo WHERE bad = $#{param}
          )
        end
      end.to raise_exception ArgumentError
    end
  end

  it 'validates numbered arguments' do
    [
      'a = $1 and b = $2 and c = $2 and c = $4',
      'a = $2 and b = $2 and c = $3',
      'a = $1 and b = $2 and c = $4'
    ].each do |params|
      expect do
        Module.new do
          include DbMod

          def_statement :bad_params, "SELECT * FROM foo WHERE #{params}"
        end
      end.to raise_exception ArgumentError
    end
  end
end
