require 'spec_helper'

describe DbMod::Statements::Configuration::MethodConfiguration do
  it 'can be constructed with a block' do
    config = subject.class.new { single(:row!).as(:json) }

    expect(config.to_hash).to eq(single: :row!, as: :json)
  end

  it 'can be constructed with named args' do
    config = subject.class.new as: :json

    expect(config.to_hash).to eq(as: :json)
  end

  it 'can be constructed from another config object' do
    base = subject.class.new { single(:row!).as(:json) }
    config = subject.class.new base

    expect(config.to_hash).to eq(single: :row!, as: :json)
  end

  it 'can be constructed from a lambda proc' do
    base = ->() { as(:csv) }
    config = subject.class.new base

    expect(config.to_hash).to eq(as: :csv)
  end

  it 'can be assembled from multiple sources' do
    base = { as: :json, single: :row, defaults: [1, 2, 3] }
    csv = ->() { as(:csv) }

    config = subject.class.new(base, csv) { defaults 3, 4, 5 }
    expect(config.to_hash).to eq(single: :row, as: :csv, defaults: [3, 4, 5])
  end

  it 'validates arguments' do
    expect { subject.class.new 1, 2, 3 }.to raise_exception ArgumentError
  end
end
