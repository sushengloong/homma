module Homma
  class BacktestBroker

    def initialize context
      @context = context
    end

    # assuming order gets filled immediately
    def execute_order symbol, direction, quantity
      @context.events.push Event.new(
        :fill,
        datetime: Time.now,
        symbol: symbol,
        direction: direction,
        quantity: quantity,
        cost: nil,
        remaining: 0
      )
    end

  end
end
