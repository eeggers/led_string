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

    @serial = Serial.new @tty, @baudrate

    # initialize all of the LEDs to off
    @leds = (0..@led_count-1).map{ {r:0, g:0, b:0} }

    # and apply a pattern as appropriate
    pattern_fill(@pattern, repeat: @repeat) if @pattern

    # finally display the string
    sync_all
    render!
  end

  # set individual LED, immediately sync and render
  def set! index, rgb
    set index, rgb
    sync index
    render!
    @leds[index]
  end

  # set all data, immediately sync and render
  def set_all! rgb
    set_all rgb
    sync 0 # we can send less serial
    fill!  # data with this shortcut
    render!
    @leds[0]
  end

  # shift all data, immediately sync and render
  def shift! direction=:right
    shift direction
    sync_all
    render!
  end

  def pattern_fill! pattern, options={repeat:true}
    pattern_fill pattern, options
    sync_all
    render!
  end

  def clear!
    pattern_fill [{}]
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

  def pattern_fill pattern, options={repeat: true}
    @pattern = pattern
    @repeat = options[:repeat]
    @leds.each_with_index do |led, index|
      tmp = {r:0,g:0,b:0}
      if index < @pattern.length || @repeat
        tmp.merge! @pattern[index % @pattern.length]
      end
      led.merge! tmp
    end
  end

  def clear
    pattern_fill [{}]
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

  # fill the whole string with the value of the first pixel and render
  def fill!
    serial_write "fill;"
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