require 'spec_helper'

describe DbMod::Statements::Configuration::Defaults do
  before do
    @conn = instance_double 'PGconn'
    allow(@conn).to receive(:prepare)
    allow(PGconn).to receive(:connect).and_return(@conn)
  end

  context 'named arguments' do
    subject do
      Module.new do
        include DbMod

        def_statement(:a, %(
          SELECT *
            FROM foo
           WHERE id = $id
             AND x > $min
        )) { defaults min: 10 }

        def_prepared(:b, %(
          INSERT INTO foo
            (x, name)
          VALUES
            ($x, $name)
        )) { single(:value!).defaults x: 100, name: 'dunno' }
      end.create db: 'testdb'
    end

    it 'defines default method arguments' do
      expect(@conn).to receive(:exec_params) do |_, params|
        expect(params).to eq([1, 10])
      end
      subject.a id: 1

      expect(@conn).to(
        receive(:exec_prepared).with('b', [100, 'dunno']).and_return(
          [{ 'id' => '1' }]
        )
      )
      expect(subject.b).to eq('1')
    end

    it 'defers to provided values' do
      expect(@conn).to receive(:exec_params) do |_, params|
        expect(params).to eq([2, 20])
      end
      subject.a id: 2, min: 20

      expect(@conn).to(
        receive(:exec_prepared).with('b', [200, 'name']).and_return(
          [{ 'id' => '7' }]
        )
      )
      subject.b name: 'name', x: 200
    end

    it 'allows explicit nil' do
      expect(@conn).to(
        receive(:exec_prepared).with('b', [nil, 'dunno']).and_return(
          [{ 'id' => '8' }]
        )
      )
      subject.b x: nil
    end

    it 'requires parameters without defaults' do
      expect(@conn).not_to receive(:exec_params)
      expect { subject.a }.to raise_exception ArgumentError
    end
  end

  context 'indexed arguments' do
    subject do
      Module.new do
        include DbMod

        def_statement(:a, %(
          SELECT *
            FROM foo
           WHERE id = $1
             AND x > $2
        )) { defaults 10 }

        def_prepared(:b, %(
          INSERT INTO foo
            (x, name)
          VALUES
            ($1, $2)
          RETURNING id
        )) { defaults(100, 'huh?').single(:row!).as(:json) }
      end.create db: 'testdb'
    end

    it 'defines default method arguments' do
      expect(@conn).to(
        receive(:exec_prepared).with('b', [100, 'huh?']).and_return(
          [{ 'id' => '2' }]
        )
      )
      expect(subject.b).to eq('{"id":"2"}')
    end

    it 'fills in arguments from the right hand side' do
      expect(@conn).to receive(:exec_params) do |_, params|
        expect(params).to eq([4, 10])
      end
      subject.a 4

      expect(@conn).to(
        receive(:exec_prepared).with('b', [102, 'huh?']).and_return(
          [{ 'id' => '5' }]
        )
      )
      subject.b 102
    end

    it 'defers to provided values' do
      expect(@conn).to receive(:exec_params) do |_, params|
        expect(params).to eq([5, 11])
      end
      subject.a 5, 11

      expect(@conn).to(
        receive(:exec_prepared).with('b', [101, 'nom']).and_return(
          [{ 'id' => '6' }]
        )
      )
      subject.b 101, 'nom'
    end

    it 'asserts correct parameter count' do
      expect { subject.a }.to raise_exception ArgumentError
      expect { subject.b 1, 2, 3 }.to raise_exception ArgumentError
    end
  end

  context 'procs as defaults' do
    MINS_FOR = {
      1 => 10,
      2 => 20
    }

    subject do
      Module.new do
        include DbMod

        def min_for(args)
          MINS_FOR[args[:id]]
        end

        def_prepared(:a, %(
          SELECT *
            FROM foo
           WHERE id = $1
             AND x > $2
        )) { defaults ->(args) { MINS_FOR[args.first] } }

        def_prepared(:b, %(
          SELECT *
            FROM foo
           WHERE id = $id
             AND x > $min
        )) { defaults min: ->(args) { min_for(args) } }
      end.create db: 'testdb'
    end

    it 'works with indexed parameters' do
      expect(@conn).to receive(:exec_prepared).with('a', [1, 10])
      subject.a(1)

      expect(@conn).to receive(:exec_prepared).with('a', [2, 20])
      subject.a(2)

      expect(@conn).to receive(:exec_prepared).with('a', [1, 11])
      subject.a(1, 11)

      expect(@conn).to receive(:exec_prepared).with('a', [3, nil])
      subject.a(3)
    end

    it 'works with named parameters' do
      expect(@conn).to receive(:exec_prepared).with('b', [1, 10])
      subject.b(id: 1)

      expect(@conn).to receive(:exec_prepared).with('b', [2, 20])
      subject.b(id: 2)

      expect(@conn).to receive(:exec_prepared).with('b', [1, 11])
      subject.b(id: 1, min: 11)

      expect(@conn).to receive(:exec_prepared).with('b', [3, nil])
      subject.b(id: 3)

      expect { subject.b }.to raise_exception ArgumentError
    end
  end

  context 'definition-time validation' do
    it 'must use named or indexed parameters appropriately' do
      expect do
        Module.new do
          include DbMod

          def_statement(:a, 'SELECT * FROM foo WHERE x = $1') do
            defaults id: 1
          end
        end
      end.to raise_exception ArgumentError

      expect do
        Module.new do
          include DbMod

          def_prepared(:a, 'SELECT * FROM foo WHERE id = $id') { defaults 1 }
        end
      end.to raise_exception ArgumentError
    end

    it 'asserts that mixed default types are not given' do
      expect do
        Module.new do
          include DbMod

          def_statement(:a, 'SELECT * FROM foo WHERE id = $id') do
            defaults 1, id: 2
          end
        end
      end.to raise_exception ArgumentError
    end

    it 'may not be specified more than once' do
      expect do
        Module.new do
          include DbMod

          def_statement(:a, 'SELECT * FROM foo WHERE x = $1') do
            defaults 1
            defaults 2
          end
        end
      end.to raise_exception DbMod::Exceptions::BadMethodConfiguration
    end

    it 'disallows too many defaults' do
      expect do
        Module.new do
          include DbMod

          def_statement(:a, 'SELECT * FROM foo WHERE x=$1') { defaults 1, 2 }
        end
      end.to raise_exception ArgumentError

      expect do
        Module.new do
          include DbMod

          def_statement(:a, 'SELECT 1') { defaults 10 }
        end
      end.to raise_exception ArgumentError
    end
  end
end
