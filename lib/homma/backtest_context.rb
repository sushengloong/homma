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
      @symbols = %w{ AAPL FB }
      @starting_capital = 10_000
      @commission_per_trade = 25

      # components
      @logger = nil || Logger.new(STDOUT)
      @feeder = nil || YahooFinanceFeeder.new(self)
      @strategy = nil || MovingAverageCrossoverStrategy.new(self, 50, 250)
      @broker = nil
      @portfolio = nil
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
            @logger.info "No more event, move on to next outer loop"
            break
          end

          event = @events.shift
          if event.nil?
            @logger.warn 'Encountered nil event'
            next
          end

          @logger.info event.type
          case event.type
          when :bar
            @strategy.on_bar event.data[:latest_bar]
          when :signal
            @logger.debug event.data[:direction]
          when :order
          when :fill
          else
            @logger.warn "Unknown event type #{event.type}"
          end
        end
      end
    end

    def trading_ended?
      @current_date > @end_date
    end

  end
end
