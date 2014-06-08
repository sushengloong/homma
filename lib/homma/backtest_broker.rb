module Homma
  class BacktestBroker

    def initialize context
      @context = context
    end

    # assuming order gets filled immediately
    def execute_order event
      @context.events.push Event.new(
        :fill,
        datetime: Time.now,
        symbol: event.data[:symbol],
        direction: event.data[:direction],
        quantity: event.data[:quantity],
        cost: nil,
        remaining: 0
      )
    end

  end
end
