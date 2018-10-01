require 'rubyserial'

class LedString
  attr_accessor :led_count,
                :tty,
                :baudrate,
                :serial,
                :leds,
                :pattern,
                :repeat,
                :verbose

  DEFAULT_OPTIONS = {
    led_count: 30,
    tty: "/dev/cu.usbmodem14101",
    baudrate: 115200,
    pattern: nil,
    repeat: true,
    verbose: false
  }

  def initialize options={}
    options = DEFAULT_OPTIONS.merge options
    @led_count = options[:led_count]
    @tty       = options[:tty]
    @baudrate  = options[:baudrate]
    @pattern   = options[:pattern]
    @repeat    = options[:repeat]
    @verbose   = options[:verbose]

    @frame_index = 0

    @serial = Serial.new @tty, @baudrate

    # initialize all of the LEDs to off
    @leds = (0..@led_count-1).map{ blank_led }

    # and apply a pattern as appropriate
    set_pattern(@pattern, repeat: @repeat) if @pattern

    # finally display the string
    sync_all!
  end

  # set individual LED, immediately sync and render
  def set! index, rgb
    set index, rgb
    sync index
    render!
    @leds[index]
  end

  # set buffer, immediately sync and render
  def set_all! rgb
    set_all rgb
    sync 0 # we can send less serial
    fill!  # data with this shortcut
    @leds[0]
  end

  # shift buffer, immediately sync and render
  def shift! direction=:right
    shift direction
    sync_all!
  end

  def set_pattern! pattern, options={repeat:true}
    set_pattern pattern, options
    sync_all!
  end

  def next_frame! direction=:forward
    next_frame direction
    sync_all!
  end

  def clear!
    clear
    sync_all!
  end


  #same as above, but merely update the local state
  def set index, rgb
    @leds[index].merge! rgb
  end

  def set_all rgb
    @leds.each_with_index do |led, index|
      set index, rgb
    end
    @leds.first
  end

  def shift direction=:right
    case direction
    when :left 
      @leds.push @leds.shift
    when :right
      @leds.unshift @leds.pop
    end
  end

  def set_pattern pattern, options={repeat: true}
    @pattern = pattern
    @frame_index = 0
    @repeat = options[:repeat]
    @leds.each_with_index do |led, index|
      tmp = blank_led
      if index < @pattern.length || @repeat
        tmp.merge! @pattern[index % @pattern.length]
      end
      led.merge! tmp
    end
  end

  def next_frame direction=:forward
    if direction == :forward
      @frame_index = @frame_index + 1 % @pattern.length
    elsif direction == :backward
      @frame_index = @frame_index - 1 < 0 ? @pattern.length - 1 : @frame_index - 1
    end

    @leds = (@pattern * (@led_count * 1.0 / @pattern.length).ceil).rotate(@frame_index).first @led_count
  end

  def clear
    set_pattern [blank_led]
  end

  # iterate over the leds, yield block
  def each
    @leds.each_with_index do |led, index|
      yield led, index
    end
    nil
  end

  # yield supplied block with 1/fps s delay
  def loop fps=30
    while true
      yield(self)
      sleep 1.0 / fps
    end
  end

  def blank_led
    {r:0, g:0, b:0}
  end

  #### SERIAL INTERFACE FUNCTIONS ###

  # sync specific led to string
  def sync index
    rgb_data = @leds[index]
    serial_write "#{index}:#{rgb_data[:r]},#{rgb_data[:g]},#{rgb_data[:b]};"
  end

  def sync! index
    sync index
    render!
  end

  def fill
    serial_write "fill;"
  end

  # fill the whole string with the value of the first pixel and render
  def fill!
    fill
    render!
  end

  # sync all leds to string
  def sync_all
    @leds.each_with_index {|_, index| sync index}
  end

  def sync_all!
    sync_all
    render!
  end

  # tell the led string to render
  def render!
    serial_write "render;"
  end

  # spit out the state as read from the LED string
  def list
    serial_write "list;"
    puts @serial.read(100000)
  end

  def serial_write s
    puts "serial_write: #{s}" if @verbose
    @serial.write s
  end

end