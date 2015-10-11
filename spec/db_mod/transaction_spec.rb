require 'spec_helper'

class TransactionTest
  include DbMod

  def connect
    db_connect db: 'testdb'
  end

  def transaction!
    transaction do
      query 'SELECT 1'
    end
  end

  def nested
    transaction do
      transaction do
        # Not reached
      end
    end
  end
end

describe DbMod::Transaction do
  subject { TransactionTest.new }

  before do
    @conn = instance_double 'PGconn'
    allow(@conn).to receive(:query)
    allow(subject).to receive(:db_connect!).and_return @conn
  end

  describe '#transaction' do
    it 'expects the connection to be set' do
      expect { subject.transaction! }.to raise_exception(
        DbMod::Exceptions::ConnectionNotSet
      )
    end

    it 'calls BEGIN and COMMIT' do
      subject.connect

      expect(@conn).to receive(:query).with 'BEGIN'
      expect(@conn).to receive(:query).with 'SELECT 1'
      expect(@conn).to receive(:query).with 'COMMIT'

      subject.transaction!
    end

    it 'calls ROLLBACK if there is a failure' do
      subject.connect

      expect(@conn).to receive(:query).with 'BEGIN'
      expect(@conn).to receive(:query).with('SELECT 1').and_raise 'error'
      expect(@conn).to receive(:query).with 'ROLLBACK'

      expect { subject.transaction! }.to raise_exception 'error'
    end

    it 'guards against concurrent transactions' do
      subject.connect

      expect { subject.nested }.to raise_exception(
        DbMod::Exceptions::AlreadyInTransaction
      )
    end
  end
end
