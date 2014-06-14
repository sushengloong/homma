module Homma
  class BacktestContext

    attr_accessor :events, :start_date, :end_date, :current_date,
      :symbols, :starting_capital, :commission_per_trade,
      :feeder, :logger

    def initialize
      # states
      @events = []
      @start_date = nil || Date.new(2014, 01, 01)
      @end_date = nil || Date.today
      @current_date = @start_date
      @symbols = ['AAPL'] || %w{ AAPL FB MSFT ORCL }
      @starting_capital = nil || 10_000
      @commission_per_trade = nil || 25

      # components
      @logger = nil || Logger.new(STDOUT)
      @feeder = nil || YahooFinanceFeeder.new(self)
      @strategy = nil || MovingAverageCrossoverStrategy.new(self, 50, 250)
      @portfolio = nil || Portfolio.new(self)
      @broker = nil || BacktestBroker.new(self)
    end

    def start_trading
      i = 0
      loop do
        # increase counter and advance current date
        i += 1
        @current_date += 1 unless i == 1
        @logger.info "Round: #{i} (#{@current_date.strftime('%d %b %Y')})"
        if trading_ended?
          @logger.info "Trading has ended"
          break
        else
          @feeder.next_bar
        end

        loop do
          if @events.empty?
            @logger.info ""
            break
          end

          event = @events.shift
          if event.nil?
            @logger.warn 'Encountered nil event'
            next
          end

          @logger.info ">>> #{event.data[:symbol]}: #{event.type}"
          case event.type
          when :bar
            bar = event.data[:latest_bar]
            @strategy.on_bar bar
            @portfolio.on_bar bar
          when :signal
            @portfolio.place_order event.data[:symbol], event.data[:direction]
          when :order
            @broker.execute_order event.data[:symbol], event.data[:direction], event.data[:quantity]
          when :fill
            @portfolio.on_fill event.data[:symbol], event.data[:direction], event.data[:quantity]
          else
            @logger.warn "Unknown event type #{event.type}"
          end

          @logger.info "Current Position:"
          @logger.info @portfolio.current_positions
          @logger.info "Current Holding:"
          @logger.info @portfolio.current_holdings
          @logger.info "Cash: #{@portfolio.cash.round(3)}"
          @logger.info "Commission: #{@portfolio.commission.round(3)}"
          @logger.info "Total: #{@portfolio.total.round(3)}"
          @logger.info "Sharpe Ratio: #{@portfolio.sharpe_ratios[@current_date.strftime('%Y-%m-%d')].round(3)}"

        end # inner loop
      end # outer loop

      output_performance
    end

    def output_performance
      # @logger.info @portfolio.equity_curve
      # @logger.info @portfolio.summary
    end

    def trading_ended?
      @current_date > @end_date
    end

  end
end
