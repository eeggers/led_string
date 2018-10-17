require 'rubyserial'
load 'gamma.rb'

class LedString
  attr_reader   :led_count,
                :tty,
                :baudrate,
                :serial,
                :leds,
                :gamma
  
  attr_accessor :verbose, :gamma_correction, :color_adjust

  DEFAULT_OPTIONS = {
    led_count: 30,
    tty: "/dev/tty.SLAB_USBtoUART",
    baudrate: 115200,
    verbose: false,
    gamma_correction: true,
    gamma: 2.5,
    leds: [],
    color_adjust: [1,1,1]
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
    @color_adjust     = options[:color_adjust]

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

    r = _gamma(_color_adjust(0, led[0]))
    g = _gamma(_color_adjust(1, led[1]))
    b = _gamma(_color_adjust(2, led[2]))


    tmp = [index, r, g, b].map{|byte| "00#{byte.to_s(16)}"[-2..-1]}
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
  def dump
    serial_write "d;"
    puts @serial.read(1000000)
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

  def _color_adjust i, v
    (@color_adjust[i] * v).round
  end

  def _gamma n
    return n unless @gamma_correction
    @gamma_lookup[n]
  end

  def blank_led
    [0,0,0]
  end

end
