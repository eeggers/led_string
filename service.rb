require 'sinatra'
require 'sinatra/namespace'
require 'erb'

require_relative "./led_string.rb"

class Service < Sinatra::Base
  register Sinatra::Namespace

  before do
    @led_string = LedString.new led_count: 90, type: LedString::RGBW, silent_start: true
  end

  COLORS = {
    "red" => [255,0,0,0],
    "green" => [0,255,0,0],
    "blue" => [0,0,255,0,],
    "violet" => [255,0,255,0],
    "default" => [160,70,0,160],
    "warmwhite" => [0,0,0,255],
    "brightwhite" => [255,255,255,255]
  }

  get "/" do

    @str = "this is a string"
    erb :"index.html"
  end

  get "/led_string" do
    @led_string.dump.to_s
  end

  namespace '/led_string' do

    get "/clear" do
      @led_string.clear!
      "Cleared!"
    end

    get "/load" do
      @led_string.load!
      "Loaded from EEPROM!"
    end

    get "/save" do
      @led_string.save
      "Saved to EEPROM!"
    end

    get "/dump" do
      @led_string.dump.to_s
    end

    get "/:color" do
      color = case params[:color]
      when "red"
        [255,0,0,0]
      when "green"
        [0,255,0,0]
      when "blue"
        [0,0,255,0]
      when "violet"
        [255,0,255,0]
      when "default"
        [160,70,0,160]
      when "white", "warmwhite"
        [0,0,0,255]
      when "brightwhite"
        [255,255,255,255]
      else
        nil
      end

      unless color.nil?
        @led_string.set_leds! [color]*@led_string.led_count
        "Set LEDs to #{color}!"
      else
        "Don't know that one!"
      end
    end
  end
end
