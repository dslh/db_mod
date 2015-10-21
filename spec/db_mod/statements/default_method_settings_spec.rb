require 'spec_helper'
require 'json'
require 'csv'

describe DbMod::Statements::DefaultMethodSettings do
  subject do
    Module.new do
      include DbMod

      default_method_settings do
        single(:row).as(:json).returning(&:inspect)
      end

      def_prepared(:a, 'SELECT * FROM a WHERE id = $1')
      def_prepared(:b, 'SELECT * FROM b WHERE id = $1')
      def_prepared(:c, 'SELECT * FROM c WHERE id = $1') { single(:column) }
    end
  end

  before do
    @conn = instance_double('PGconn')
    allow(@conn).to receive(:prepare)
    allow(PGconn).to receive(:connect).and_return(@conn)

    allow(@conn).to receive(:exec_prepared) do |name, args|
      [{ 'id' => args.first, name => (args.first * 2) }]
    end
  end

  it 'applies settings to all defined methods' do
    db = subject.create db: 'x'

    expect(db.a('1')).to eq('"{\"id\":\"1\",\"a\":\"11\"}"')
    expect(db.b('2')).to eq('"{\"id\":\"2\",\"b\":\"22\"}"')
  end

  it 'allows overrides to be provided for settings' do
    db = subject.create db: 'x'

    allow(@conn).to receive(:exec_prepared).and_return([
      { 'x' => '1' },
      { 'x' => '2' }
    ])
    expect(db.c('3')).to eq('"[\"1\",\"2\"]"')
  end

  it 'does not cascade to other modules' do
    parent = subject
    db = Module.new do
      include parent

      def_prepared(:d, 'SELECT * FROM d WHERE id = $1')
      def_statement(:e, 'SELECT id FROM e WHERE x = $y') do
        single(:value).returning { |id| a(id) }
      end
    end.create db: 'x'

    expect(db.d('4')).to eq([{ 'id' => '4', 'd' => '44' }])

    allow(@conn).to receive(:exec_params).and_return([{ 'id' => '5' }])
    expect(db.e(y: 'y')).to eq('"{\"id\":\"5\",\"a\":\"55\"}"')
  end
end
