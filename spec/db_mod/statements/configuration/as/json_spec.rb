require 'spec_helper'
require 'json'

describe DbMod::Statements::Configuration::As::Json do
  subject do
    Module.new do
      include DbMod

      def_statement(:statement, 'SELECT a, b FROM foo').as(:json)
      def_prepared(:prepared, 'SELECT a, b FROM bar').as(:json)
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
end
