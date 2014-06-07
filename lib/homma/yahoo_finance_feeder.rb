module Homma
  class YahooFinanceFeeder
    require 'csv'
    require 'typhoeus'

    BASE_URL = 'http://ichart.finance.yahoo.com/table.csv'

    attr_accessor :cache_bars

    def initialize context
      @context = context
      @market_data = {}
      load_cache
    end

    def next_bar
      return if @context.trading_ended?

      current_date_str = @context.current_date.strftime('%Y-%m-%d')
      latest_bar = @cache_symbols.inject({}) do |h, symbol|
        latest_symbol_bar = @cache_bars[symbol].reject! { |bar| bar[:date] == current_date_str }
        latest_symbol_bar = latest_symbol_bar.first if latest_symbol_bar
        @market_data[symbol] ||= []
        @market_data[symbol] << latest_symbol_bar
        h.merge(symbol => latest_symbol_bar)
      end
      @context.events.push Event.new(:bar, latest_bar: latest_bar)
    end

    def load_cache
      @cache_bars = {}
      hydra = Typhoeus::Hydra.new
      start_date = @context.start_date
      end_date = @context.end_date
      @context.symbols.each do |symbol|
        params = {
          s: symbol,
          a: start_date.month - 1,
          b: start_date.day,
          c: start_date.year,
          d: end_date.month - 1,
          e: end_date.day,
          f: end_date.year,
          ignore: '.csv'
        }
        request = Typhoeus::Request.new BASE_URL, params: params
        request.on_complete(&method(:on_complete))
        hydra.queue request
      end
      hydra.run
    end

    private

    def on_complete response
      if response.success?
        request = response.request
        begin
          symbol = request.options[:params][:s].to_s.upcase
        rescue
          @context.logger.error 'typhoeus cannot retrieve symbol'
        end
        @cache_bars[symbol] = []
        CSV.parse(response.body, headers: true, header_converters: :symbol) do |row|
          @cache_bars[symbol] << row.to_hash
        end
        @cache_bars[symbol].reverse! # Yahoo CSV data needs reversal
        @cache_symbols = @cache_bars.keys # refresh cache keys
      elsif response.timed_out?
        # aw hell no
        @context.logger.error 'typhoeus request got a time out'
      elsif response.code == 0
        # Could not get an http response, something's wrong.
        @context.logger.error "typhoeus HTTP error #{response.return_message}"
      else
        # Received a non-successful http response.
        @context.logger.error "typhoeus HTTP response code: #{response.code.to_s}"
      end
    end

  end
end
