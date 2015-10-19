require 'spec_helper'

describe DbMod::Statements::Configuration::Single do
  subject do
    Module.new do
      include DbMod

      def_statement(:v, 'SELECT a FROM foo') { single(:value) }
      def_prepared(:v!, 'SELECT c FROM d WHERE e = $f') { single(:value!) }

      def_prepared(:r, 'SELECT a, b FROM foo WHERE c = $1') { single(:row) }
      def_statement(:r!, 'SELECT a, b FROM foo') { single(:row!) }

      def_statement(:c, 'SELECT a FROM foo WHERE c > $min') { single(:column) }
    end.create(db: 'testdb')
  end

  before do
    @conn = instance_double 'PGconn'
    allow(@conn).to receive(:prepare)
    allow(PGconn).to receive(:connect).and_return(@conn)
  end

  context ':value, :value!' do
    it 'extracts single values' do
      expect(@conn).to receive(:query).and_return([{ 'a' => '1' }])
      expect(subject.v).to eq('1')

      expect(@conn).to receive(:exec_prepared).and_return([{ 'c' => '2' }])
      expect(subject.v! f: 1).to eq('2')
    end

    it 'can assert a single result was returned' do
      expect(@conn).to receive(:exec_prepared).and_return([])
      expect { subject.v! f: 2 }.to raise_exception DbMod::Exceptions::NoResults

      expect(@conn).to receive(:exec_prepared).and_return([
        { 'c' => '3' },
        { 'c' => '4' }
      ])
      expect { subject.v! f: 3 }.to raise_exception(
        DbMod::Exceptions::TooManyResults
      )
    end
  end

  context ':row, :row!' do
    it 'extracts single rows' do
      result = [{ 'a' => '1', 'b' => '2' }]
      expected = { 'a' => '1', 'b' => '2' }

      expect(@conn).to receive(:exec_prepared).and_return(result)
      expect(subject.r(1)).to eq(expected)

      expect(@conn).to receive(:query).and_return(result)
      expect(subject.r!).to eq(expected)
    end

    it 'can assert that a single result was returned' do
      expect(@conn).to receive(:query).and_return([])
      expect { subject.r! }.to raise_exception DbMod::Exceptions::NoResults

      expect(@conn).to receive(:query).and_return([
        { 'a' => '3', 'b' => '4' },
        { 'a' => '5', 'b' => '6' }
      ])
      expect { subject.r! }.to raise_exception(
        DbMod::Exceptions::TooManyResults
      )
    end
  end

  context ':column' do
    it 'returns the column as an array' do
      expect(@conn).to receive(:exec_params).and_return([
        { 'a' => '1' },
        { 'a' => '2' },
        { 'a' => '3' }
      ])
      expect(subject.c min: 1).to eq(%w(1 2 3))

      expect(@conn).to receive(:exec_params).and_return([])
      expect(subject.c min: 2).to eq([])
    end
  end

  it 'rejects unknown types' do
    expect do
      Module.new do
        include DbMod

        def_statement(:a, 'SELECT 1') { single(:lolwut) }
      end
    end.to raise_exception ArgumentError
  end

  it 'cannot be called twice' do
    expect do
      Module.new do
        include DbMod

        def_statement(:a, 'SELECT 1') { single(:row).single(:value) }
      end
    end.to raise_exception DbMod::Exceptions::BadMethodConfiguration
  end
end
