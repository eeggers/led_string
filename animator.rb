class Animator

  attr_reader :led_string, :led_count, :pattern, :current_frame

  DEFAULT_OPTIONS = {
    pattern: [[0,0,0]] # this could be improved...
  }

  def initialize led_string, options={}
    options = DEFAULT_OPTIONS.merge options
    self.led_string = led_string
    self.pattern = options[:pattern]
  end

  def pattern= pattern
    @frame_index = -1
    @pattern = pattern
    next_frame
    nil
  end

  def led_string= led_string
    @led_string = led_string
  end

  def next_frame
    _next_frame :forward
  end

  def next_frame!
    _next_frame! :forward
  end

  def previous_frame
    _next_frame :backward
  end

  def previous_frame!
    _next_frame! :backward
  end

  def display!
    @led_string.leds = @current_frame
    @led_string.sync!
  end

  def play!(fps=30)
    loop(fps) do |_|
      _.next_frame!
    end
  end

  def rewind!(fps=30)
    loop(fps) do |_|
      _.previous_frame!
    end
  end

  def reset!
    @frame_index = -1
    next_frame!
  end

  def loop(fps=30) # block
    raise Error("Can't loop without block!") unless block_given?
    delay = 1.0 / fps
    while true
      yield(self)
      sleep delay
    end
  end

  private

  def _next_frame! direction
    _next_frame direction
    display!
  end

  def _next_frame direction
    if direction == :forward
      @frame_index = @frame_index + 1 % @pattern.length
    elsif direction == :backward
      @frame_index = @frame_index - 1 < 0 ? @pattern.length - 1 : @frame_index - 1
    end

    @current_frame = (@pattern * (@led_string.led_count * 1.0 / @pattern.length).ceil).rotate(@frame_index).first @led_string.led_count
  end
end