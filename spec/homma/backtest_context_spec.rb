require 'spec_helper'

describe Homma::BacktestContext do
  describe '#start' do
    before(:each) do
      @context = Homma::BacktestContext.new
    end

    it "start trading without any error" do
      @context.start_trading
      expect(true).to be true
    end
  end
end
