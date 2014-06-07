module Homma
  class Event

    attr_reader :type, :data

    def initialize type, data
      @type, @data = type, data
    end
  end
end
