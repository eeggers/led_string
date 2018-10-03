module Gamma
  def self.generate_table steps, g
    tmp = (0..steps-1).map{|x| x ** g}
    max = tmp.max
    tmp.map{|x| x.fdiv(max)}
  end
end