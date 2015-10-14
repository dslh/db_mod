require 'spec_helper'
require 'csv'

describe DbMod::Statements::Configuration::As::Csv do
  subject do
    Module.new do
      include DbMod

      def_statement(:statement, 'SELECT a, b FROM foo').as(:csv)
      def_prepared(:prepared, 'SELECT c, d FROM bar').as(:csv)
    end
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
      it 'coerces results to csv' do
        expect(@conn).to receive(exec_type).and_return([
          { 'a' => '1', 'b' => '2' },
          { 'a' => '3', 'b' => '4' }
        ])

        csv = subject.create(db: 'testdb').send(method_type)
        expect(csv).to eq("a,b\n1,2\n3,4\n")
      end
    end
  end
end
