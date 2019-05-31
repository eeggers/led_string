require 'rubyserial'
load 'gamma.rb'

class LedString
  TYPES = [
    RGB = :RGB,
    RGBW = :RGBW
  ]

  attr_reader   :led_count,
                :tty,
                :baudrate,
                :serial,
                :leds,
                :gamma
  
  attr_accessor :verbose, :gamma_correction, :color_adjust

  DEFAULT_OPTIONS = {
    led_count: 30,
    type: RGB,
    tty: "/dev/tty.SLAB_USBtoUART",
    baudrate: 115200,
    verbose: false,
    gamma_correction: true,
    gamma: 2.2,
    leds: []
  }

  def initialize options={}
    options = DEFAULT_OPTIONS.merge options
    @led_count        = options[:led_count]

    @tty              = options[:tty]
    @baudrate         = options[:baudrate]
    @pattern          = options[:pattern]
    @repeat           = options[:repeat]
    @verbose          = options[:verbose]
    @gamma_correction = options[:gamma_correction]
    self.gamma        = options[:gamma]
    @type             = options[:type]

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

  def gamma= gamma
    @gamma = gamma
    @gamma_lookup = Gamma.generate_table(256, @gamma).map{|x| (x * 255).round}
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

  #### SERIAL INTERFACE FUNCTIONS ###

  # sync specific led to string
  # format is iirrggbb; (index, red, green, blue; 2 hex digits each)
  def sync_single index
    led = @leds[index]

    tmp = [index] + led.map{|v|_gamma(v)};

    tmp = tmp.map{|byte| "00#{byte.to_s(16)}"[-2..-1]}
    serial_write "#{tmp.join};"
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

  def load!
    load
    render!
  end

  # tell the led string to render
  def render!
    serial_write "r;"
  end

  # spit out the state as read from the LED string
  # need to tail -f the tty device to actually see this
  def dump
    serial_write "d;"
  end

  def save
    sync
    serial_write "s;"
  end

  def load
    serial_write "l;"
  end

  def serial_write s
    puts "serial_write: #{s}" if @verbose
    @serial.write s
    nil
  end

  private

  def _gamma n
    return n unless @gamma_correction
    @gamma_lookup[n]
  end

  def blank_led
    if @type == RGBW
      [0,0,0,0]
    else
      [0,0,0]
    end
  end

end
