require 'spec_helper'

module CreateTest
  include DbMod

  def do_thing
    query 'SELECT 1'
  end
end

describe DbMod::Create do
  before do
    @conn = instance_double 'PGconn'
    allow(PGconn).to receive(:connect).and_return(@conn)
  end

  it 'creates module instances' do
    expect(PGconn).to receive(:connect).with(
      nil, 5432, '', '', 'testdb', ENV['USER'], 'trusted?'
    )

    test = CreateTest.create db: 'testdb'

    expect(@conn).to receive(:query).with('SELECT 1')

    test.do_thing
  end

  it 'can be supplied an existing connection' do
    expect(PGconn).not_to receive(:connect)
    expect(@conn).to receive(:is_a?).with(PGconn).and_return true

    test = CreateTest.create @conn

    expect(@conn).to receive(:query).with('SELECT 1')

    test.do_thing
  end
end
