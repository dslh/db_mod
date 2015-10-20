require 'spec_helper'
require 'csv'

describe DbMod::Statements::Configuration::Returning do
  before do
    @conn = instance_double 'PGconn'
    allow(@conn).to receive(:prepare)
    allow(PGconn).to receive(:connect).and_return(@conn)

    allow(@conn).to receive(:exec_prepared).with('a').and_return([
      { 'name' => 'cow', 'sound' => 'moo' },
      { 'name' => 'dog', 'sound' => 'woof' }
    ])
  end

  subject do
    Module.new do
      include DbMod

      def_prepared(:a, 'SELECT name, sound FROM animals') do
        returning do |animals|
          animals.map do |animal|
            "the #{animal['name']} goes #{animal['sound']}"
          end.join ' and '
        end
      end

      def send_email(*); end

      def_prepared(:b, 'SELECT address FROM email WHERE id = $1') do
        single(:value)

        returning { |email| send_email(email, a) }
      end

      def_prepared(:c, 'SELECT * FROM bar') do
        as(:csv)

        returning { |json| send_email('som@body', json) }
      end
    end.create db: 'test'
  end

  it 'performs arbitrary result transformations' do
    expect(subject.a).to eq(
      'the cow goes moo and the dog goes woof'
    )
  end

  it 'has access to module instance scope' do
    allow(@conn).to receive(:exec_prepared).with('b', [1]).and_return([
      { 'address' => 'ex@mple' }
    ])
    expect(subject).to receive(:send_email).with(
      'ex@mple',
      'the cow goes moo and the dog goes woof'
    )
    subject.b(1)
  end

  it 'works with as' do
    allow(@conn).to receive(:exec_prepared).and_return([
      { 'a' => '1', 'b' => '2' },
      { 'a' => '3', 'b' => '4' }
    ])
    expect(subject).to receive(:send_email).with('som@body', "a,b\n1,2\n3,4\n")
    subject.c
  end
end
