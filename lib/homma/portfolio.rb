module Homma
  class Portfolio

    DIRECTION_MAPPING = {
      buy: 1,
      sell: -1
    }

    def initialize context
      @context = context
      @commission_per_trade = @context.commission_per_trade

      @current_positions = context.symbols.inject({}) do |h, symbol|
        h.merge(symbol => 0.0)
      end

      @current_holdings = context.symbols.inject({}) do |h, symbol|
        h.merge(symbol => 0.0)
      end

      @cash = @context.starting_capital
      @commissions = 0.0
      @total = @cash + @commissions
    end

    def on_bar event
      event.data[:symbol]
    end

    def on_fill event
      symbol = event.data[:symbol]
      quantity = event.data[:quantity]
      fill_cost = @context.feeder.market_data[symbol].last[:adj_close]

      # update positions
      fill_direction = DIRECTION_MAPPING[event.data[:direction]].to_i
      @current_positions[symbol] += (fill_direction * quantity)

      order_fill_cost = @current_positions[symbol] * fill_cost
      order_commission = @current_positions[symbol] * @commission_per_trade
      order_total_cost = order_fill_cost + order_commission

      # update holdings
      @current_holdings[symbol] += order_fill_cost
      @commissions += order_commission
      @cash -= order_total_cost
      @total -= order_total_cost
    end

    def place_order event
      symbol = event.data[:symbol]
      direction = event.data[:direction]
      order_quantity = 100 # TODO take strength into consideration
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

  end
end
