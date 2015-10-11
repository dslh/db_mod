require 'spec_helper'

class DbModTest
  include DbMod

  def connect(options = {})
    db_connect options
  end

  def query!
    query 'SELECT 1'
  end

  def conn!
    conn
  end

  def use_conn(conn)
    self.conn = conn
  end
end

describe DbMod do
  subject { DbModTest.new }

  before do
    @conn = instance_double 'PGconn'
    allow(subject).to receive(:db_connect!).and_return @conn
  end

  describe '#db_connect' do
    it 'accepts connection options' do
      options = {
        db: 'testdb',
        host: 'testhost',
        port: 5432,
        user: 'testuser',
        pass: 'testpass'
      }

      expect(subject).to receive(:db_connect).with(options)
      subject.connect(options)
    end

    it 'fills in default values' do
      expect(subject).to receive(:db_connect!).with(
        db: 'testdb',
        port: 5432,
        user: ENV['USER'],
        pass: 'trusted?'
      )
      subject.connect(db: 'testdb')
    end

    specify ':db is mandatory' do
      expect { subject.connect }.to raise_exception ArgumentError
    end

    it 'is protected' do
      expect { subject.db_connect }.to raise_exception NoMethodError
    end

    it 'must be called before the connection can be used' do
      expect { subject.query! }.to raise_exception(
        DbMod::Exceptions::ConnectionNotSet
      )
      expect(subject.conn!).to be_nil

      subject.connect db: 'testdb'

      expect(@conn).to receive(:query).with('SELECT 1')
      expect { subject.query! }.not_to raise_exception
      expect(subject.conn!).to be(@conn)
    end
  end

  describe '#conn=' do
    it 'is protected' do
      expect { subject.conn = @conn }.to raise_exception NoMethodError
    end

    it 'can be used instead of db_connect for initialization' do
      subject.use_conn(@conn)
      expect(subject.conn!).to be(@conn)

      expect(@conn).to receive(:query).with('SELECT 1')
      expect { subject.query! }.not_to raise_exception
    end
  end
end
