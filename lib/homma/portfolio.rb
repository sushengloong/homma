module Homma
  class Portfolio

    attr_accessor :current_positions, :current_holdings,
      :cash, :commission, :total, :returns,
      :sharpe_ratios, :max_drawdowns, :drawdown_duration

    DIRECTION_MAPPING = {
      buy: 1,
      sell: -1
    }

    def initialize context
      @context = context
      @commission_per_trade = @context.commission_per_trade

      @current_positions = context.symbols.inject({}) do |h, symbol|
        h.merge(symbol => 0)
      end

      @current_holdings = context.symbols.inject({}) do |h, symbol|
        h.merge(symbol => 0.0)
      end

      @cash = @total = @context.starting_capital.to_f
      @commission = 0.0
      @returns = {}
      @sharpe_ratios = {}
      @max_drawdowns = {}
      @drawdown_duration = {}
    end

    def on_bar bar
      bar.each do |symbol, data|
        if !data.nil? && data.has_key?(:adj_close)
          @current_holdings[symbol] = @current_positions[symbol] * data[:adj_close]
        end
      end
      new_total = @cash + @current_holdings.inject(0) { |sum, (symbol, value)| sum + value }
      date_str = @context.current_date.strftime('%Y-%m-%d')
      @returns[date_str] = new_total / @total - 1
      @sharpe_ratios[date_str] = calculate_sharpe_ratio @returns.values, @returns.length
      @max_drawdowns[date_str], @drawdown_duration[date_str] = calculate_drawdowns @returns
      @total = new_total
    end

    def on_fill symbol, direction, quantity
      fill_cost = @context.feeder.market_data[symbol].last[:adj_close]

      # update positions
      fill_direction = DIRECTION_MAPPING[direction].to_i
      @current_positions[symbol] += (fill_direction * quantity)

      order_fill_cost = @current_positions[symbol] * fill_cost
      order_commission = @commission_per_trade # assuming flat commission per trade
      order_total_cost = order_fill_cost + order_commission

      # update holdings
      @current_holdings[symbol] += order_fill_cost
      @commission += order_commission
      @cash -= order_total_cost
      @total = @cash + @current_holdings[symbol]
    end

    def place_order symbol, direction
      # max out order quantity with all cash we have
      order_quantity = ( (@cash - @commission_per_trade) / @context.feeder.market_data[symbol].last[:adj_close]).floor
      current_quantity = @current_positions[symbol]
      direction, quantity = if direction == :long && current_quantity == 0
                         [:buy, order_quantity]
                       elsif direction == :short && current_quantity == 0
                         [:sell, order_quantity]
                       elsif direction == :exit && currrent_quantity > 0
                         [:sell, current_quantity.to_i.abs]
                       elsif direction == :exit && current_quantity < 0
                         [:buy, current_quantity.to_i.abs]
                       end
      @context.events.push Event.new(:order, symbol: symbol, direction: direction, quantity: quantity)
    end

    private

    def calculate_sharpe_ratio returns, periods
      Math.sqrt(periods) * Math.mean(returns) / Math.std(returns)
    end

    def calculate_drawdowns returns
      drawdown = {}
      duration = {}
      highest_watermark = {}
      date_format = '%Y-%m-%d'
      @context.start_date.upto(@context.end_date) do |date|
        prev_date_str = (date - 1).strftime date_format
        date_str = date.strftime date_format
        watermark = [ highest_watermark[prev_date_str].to_f, returns[date_str].to_f ].max
        highest_watermark[date_str] = watermark
        drawdown[date_str] = highest_watermark[date_str].to_f - returns[date_str].to_f
        duration[date_str] = drawdown[date_str] == 0 ? 0 : duration[prev_date_str] + 1
      end
      [ drawdown.values.max, duration.values.max ]
    end

  end
end
