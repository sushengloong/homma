module Math

  def self.sum array
    array.inject(0) { |acc, x| acc + x }
  end

  def self.mean array
    sum(array) / array.length.to_f
  end

  def self.var array
    return 0.0 if array.length <= 1
    m = mean array
    sum_squared_diff = array.inject(0) { |acc, x| acc + (x - m) ** 2 }
    sum_squared_diff / (array.length - 1.0)
  end

  def self.std array
    Math.sqrt var(array)
  end

end
