require 'rubyserial'

class LedString2
  attr_reader   :led_count,
                :tty,
                :baudrate,
                :serial,
                :leds
  
  attr_accessor :verbose

  DEFAULT_OPTIONS = {
    led_count: 30,
    tty: "/dev/cu.usbmodem14101",
    baudrate: 115200,
    verbose: false,
    leds: []
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

    # initialize the leds
    self.leds = options[:leds]

    # finally display the string
    sync!
  end

  # if extras are supplied, ignore them, if not enough are supplied, fill with zeros
  def leds= leds
    @leds = leds.clone.fill(blank_led, leds.length..@led_count-1).first(@led_count)
  end

  def set_leds leds
    self.leds = leds
  end

  def set_leds! leds
    set_leds leds
    sync!
  end

  def set_led n, led
    @leds[n] = led
  end

  def set_led! n, led
    set_led n, led
    sync_single! n
  end

  def clear!
    clear
    sync!
  end

  def clear
    self.leds= []
  end


  def blank_led
    {r: 0, g: 0, b: 0}
  end

  #### SERIAL INTERFACE FUNCTIONS ###

  # sync specific led to string
  def sync_single index
    rgb_data = @leds[index]
    serial_write "#{index}:#{rgb_data[:r]},#{rgb_data[:g]},#{rgb_data[:b]};"
  end

  def sync_single! index
    sync_single index
    render!
  end

  # sync all leds to string
  def sync
    @leds.each_with_index {|_, index| sync_single index}
  end

  def sync!
    sync
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
    nil
  end

end