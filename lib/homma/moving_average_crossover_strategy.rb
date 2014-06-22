module Homma
  class MovingAverageCrossoverStrategy

    def initialize context, short_lookback_period, long_lookback_period
      @context = context
      @short_lookback_period = short_lookback_period
      @long_lookback_period = long_lookback_period
      @positions = @context.symbols.inject({}) do |h, symbol|
        h.merge(symbol => :out)
      end
    end

    def on_bar bar
      @context.symbols.each do |symbol|
        position = @positions[symbol]
        short_sma = moving_average symbol, @short_lookback_period
        long_sma = moving_average symbol, @long_lookback_period
        if short_sma > long_sma && position == :out
          @context.events.push Event.new(:signal, symbol: symbol, direction: :long, strength: 1.0)
          @positions[symbol] = :long
        elsif short_sma < long_sma && position == :long
          @context.events.push Event.new(:signal, symbol: symbol, direction: :exit, strength: 1.0)
          @positions[symbol] = :out
        end
      end
    end

    def moving_average symbol, lookback_period
      price_sum = @context.feeder
        .market_data[symbol]
        .compact
        .last(lookback_period)
        .inject(0) { |sum, bar| sum + bar[:adj_close].to_f }
      price_sum / lookback_period.to_f
    end

  end
end
