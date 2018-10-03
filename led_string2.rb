require 'rubyserial'

class LedString2
  attr_reader   :led_count,
                :tty,
                :baudrate,
                :serial,
                :leds
  
  attr_accessor :verbose, :gamma_correction

  DEFAULT_OPTIONS = {
    led_count: 30,
    tty: "/dev/cu.usbmodem14101",
    baudrate: 230400,
    verbose: false,
    gamma_correction: true,
    leds: []
  }

  GAMMA = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2,
    2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5,
    6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 11, 11,
    11, 12, 12, 13, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18,
    19, 19, 20, 21, 21, 22, 22, 23, 23, 24, 25, 25, 26, 27, 27, 28,
    29, 29, 30, 31, 31, 32, 33, 34, 34, 35, 36, 37, 37, 38, 39, 40,
    40, 41, 42, 43, 44, 45, 46, 46, 47, 48, 49, 50, 51, 52, 53, 54,
    55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
    71, 72, 73, 74, 76, 77, 78, 79, 80, 81, 83, 84, 85, 86, 88, 89,
    90, 91, 93, 94, 95, 96, 98, 99,100,102,103,104,106,107,109,110,
    111,113,114,116,117,119,120,121,123,124,126,128,129,131,132,134,
    135,137,138,140,142,143,145,146,148,150,151,153,155,157,158,160,
    162,163,165,167,169,170,172,174,176,178,179,181,183,185,187,189,
    191,193,194,196,198,200,202,204,206,208,210,212,214,216,218,220,
    222,224,227,229,231,233,235,237,239,241,244,246,248,250,252,255
  ]

  def initialize options={}
    options = DEFAULT_OPTIONS.merge options
    @led_count = options[:led_count]
    @tty       = options[:tty]
    @baudrate  = options[:baudrate]
    @pattern   = options[:pattern]
    @repeat    = options[:repeat]
    @verbose   = options[:verbose]
    @gamma_correction = options[:gamma_correction]

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

  def gamma n
    return n unless @gamma_correction
    GAMMA[n]
  end

  #### SERIAL INTERFACE FUNCTIONS ###

  # sync specific led to string
  # format is iirrggbb; (index, red, green, blue; 2 hex digits each)
  def sync_single index
    led = @leds[index]
    serial_write "#{[index, gamma(led[:r]), gamma(led[:g]), gamma(led[:b])].map{|byte| "00#{byte.to_s(16)}"[-2..-1]}.join};"
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
    serial_write "r;"
  end

  # spit out the state as read from the LED string
  def list
    serial_write "l;"
    puts @serial.read(100000)
  end

  def serial_write s
    puts "serial_write: #{s}" if @verbose
    @serial.write s
    nil
  end

end