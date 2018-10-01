module Generators
  # generate a color wheel of pixel_count many pixels
  def self.color_wheel pixel_count, options={s: 1, v: 1}
    step = 360.0 / (pixel_count - 1)
    results = []
    pixel_count.times do |i|
      results << hsv_to_rgb(options.merge({h: i * step}))
    end
    results
  end

  # Creat a transition from rgb1 to rgb2 in pixel_count many pixesl
  def self.gradient rgb1, rgb2, pixel_count
    difference = diff rgb2, rgb1

    steps = difference.map{|k, v| {k => v * 1.0 / (pixel_count-1)}}.reduce(:merge)
    results = []
    pixel_count.times do |i|
      d = steps.map{|k, v| {k => v * i}}.reduce(:merge)
      results << rgb1.merge(d){|k, v1, v2| constrain(v1 + v2)}
    end
    results
  end

  def self.reflect pattern
    [].concat(pattern).concat(pattern.reverse)
  end

  def self.diff rgb1, rgb2
    rgb1.merge(rgb2){|k, v1, v2| v1 - v2}
  end

  def self.constrain v, options={min: 0, max: 255, round: true}
    v = v.round if options[:round]
    return options[:min] if v < options[:min]
    return options[:max] if v > options[:max]
    v
  end

  def self.hsv_to_rgb hsv
    h = hsv[:h] % 360 # support laziness so we don't need to be strict about 0 <= h < 360
    s = hsv[:s] # 0 <= s <= 1
    v = hsv[:v] # 0 <= v <= 1

    # some intermediate values
    c = v * s
    x = c * (1 - ((h / 60.0) % 2 - 1).abs)
    m = v - c

    # do the angly bits
    if      0 <= h && h <  60
      r,g,b = [c,x,0]
    elsif  60 <= h && h < 120
      r,g,b = [x,c,0]
    elsif 120 <= h && h < 180
      r,g,b = [0,c,x]
    elsif 180 <= h && h < 240
      r,g,b = [0,x,c]
    elsif 240 <= h && h < 300
      r,g,b = [x,0,c]
    elsif 300 <= h && h < 360
      r,g,b = [c,0,x]
    end

    {r: constrain((r+m) * 255), g: constrain((g+m) * 255), b: constrain((b+m) * 255)}
  end

end