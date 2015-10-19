require 'spec_helper'
require 'json'

describe DbMod::Statements::Configuration::As::Json do
  subject do
    Module.new do
      include DbMod

      def_statement(:statement, 'SELECT a, b FROM foo') { as(:json) }
      def_prepared(:prepared, 'SELECT a, b FROM bar') { as(:json) }

      def_statement(
        :single,
        'SELECT * FROM foo WHERE a = $1'
      ) { single(:row).as(:json) }

      def_statement(
        :single!,
        'SELECT * FROM foo WHERE a = $1'
      ) { single(:row!).as(:json) }

      def_statement(:col, 'SELECT a FROM foo') { single(:column).as(:json) }
    end.create(db: 'testdb')
  end

  before do
    @conn = instance_double 'PGconn'
    allow(@conn).to receive(:prepare)
    allow(PGconn).to receive(:connect).and_return @conn
  end

  {
    statement: :query,
    prepared: :exec_prepared
  }.each do |method_type, exec_type|
    context "#{method_type} methods" do
      it 'coerces results to json' do
        expect(@conn).to receive(exec_type).and_return([
          { 'a' => '1', 'b' => 'foo' },
          { 'a' => '2', 'b' => nil }
        ])

        json = subject.send(method_type)
        expect(json).to eq(
          '[{"a":"1","b":"foo"},{"a":"2","b":null}]'
        )
      end
    end
  end

  it 'can be chained with single(:row)' do
    result = [{ 'a' => '1', 'b' => '2' }]
    expected = '{"a":"1","b":"2"}'

    expect(@conn).to receive(:exec_params).exactly(2).times.and_return(result)
    expect(subject.single(1)).to eq(expected)
    expect(subject.single!(2)).to eq(expected)
  end

  it 'can be chained with single(:column)' do
    result = [{ 'a' => '1' }, { 'a' => '2' }, { 'a' => '3' }]
    expect(@conn).to receive(:query).and_return(result)
    expect(subject.col).to eq('["1","2","3"]')
  end
end
