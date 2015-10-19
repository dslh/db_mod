require 'spec_helper'

# See submodules for more
describe DbMod::Statements::Configuration::As do
  it 'disallows unknown coercions' do
    expect do
      Module.new do
        include DbMod

        def_statement(:foo, 'SELECT 1') { as(:lolwut) }
      end
    end.to raise_exception ArgumentError
  end

  it 'disallows multiple coercions' do
    expect do
      Module.new do
        include DbMod

        def_statement(:foo, 'SELECT 1') { as(:json).as(:csv) }
      end
    end.to raise_exception DbMod::Exceptions::BadMethodConfiguration
  end
end
