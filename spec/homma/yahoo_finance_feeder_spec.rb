require 'spec_helper'

describe Homma::YahooFinanceFeeder do
  describe '#load_cache' do
    it 'load data into cache' do
      feeder = Homma::YahooFinanceFeeder.new Homma::BacktestContext.new
      expect(feeder.cache_bars).not_to be_empty
    end
  end
end
