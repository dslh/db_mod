require 'spec_helper'

# See submodules for more
describe DbMod::As do
  it 'disallows unknown coercions' do
    expect do
      Module.new do
        include DbMod

        def_statement(:foo, 'SELECT 1').as(:lolwut)
      end
    end.to raise_exception ArgumentError
  end
end
