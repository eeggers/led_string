#include <FastLED.h>
#include <EEPROM.h>

#define BAUD_RATE 115200
#define SERIAL_TIMEOUT 1000

#define LED_COUNT 256
#define LED_PIN 5

byte chars_to_byte(unsigned char, unsigned char);
void display_led(int);

CRGB leds[LED_COUNT];
char command[25];

void setup() {
  Serial.begin(BAUD_RATE);
  Serial.setTimeout(SERIAL_TIMEOUT);

  FastLED.addLeds<NEOPIXEL, LED_PIN>(leds, LED_COUNT);
  eeprom_load();
  FastLED.show();
}

void loop() {
  while (Serial.available() > 0) {
    Serial.readStringUntil(';').toCharArray(command, 25);
    if (command[1] == '\0') {
      switch (command[0]) {
        case 'r': // RENDER
          render();
          break;
        case 'c': // CLEAR
          clear();
          break;
        case 'd': // DUMP
          dump();
          break;
        case 's': // SAVE
          eeprom_save();
          break;
        case 'l': // LOAD
          eeprom_load();
          break;
      }
    } else {      // SET LED
      set_led(command);
    }
  }
}

void render() {
  FastLED.show();
}

void clear() {
  for (int i = 0; i < LED_COUNT; i++) {
    leds[i].red   = 0;
    leds[i].green = 0;
    leds[i].blue  = 0;
  }
  FastLED.show();
}


void dump() {
  Serial.println("---BEGIN DUMP---");
  for (int i = 0; i < LED_COUNT; i++) {
    Serial.print("LEDS[");Serial.print(i);Serial.print("] = [");
    Serial.print(leds[i].red);
    Serial.print(",");Serial.print(leds[i].green);
    Serial.print(",");Serial.print(leds[i].blue);
    Serial.println("]");
  }
  Serial.println("---END DUMP---");
}

void eeprom_save() {
  for (int i = 0; i < LED_COUNT; i++) {
    EEPROM.write(3 * i, leds[i].red);
    EEPROM.write(3 * i + 1, leds[i].green);
    EEPROM.write(3 * i + 2, leds[i].blue);
  }
}

void eeprom_load() {
  for (int i = 0; i < LED_COUNT; i++) {
    leds[i].red   = EEPROM.read(3 * i);
    leds[i].green = EEPROM.read(3 * i + 1);
    leds[i].blue  = EEPROM.read(3 * i + 2);
  }
}

void set_led(char *command) {
  byte index = chars_to_byte(command[0], command[1]);
  leds[index].red   = chars_to_byte(command[2], command[3]);
  leds[index].green = chars_to_byte(command[4], command[5]);
  leds[index].blue  = chars_to_byte(command[6], command[7]); 
}


// convert a pair of ascii hex charcters to a byte
// chars_to_byte('1', 'f') => 31
byte chars_to_byte(unsigned char upper_nibble, unsigned char lower_nibble) {
  if (upper_nibble > '9') upper_nibble -= 7;
  if (lower_nibble > '9') lower_nibble -= 7;
  return (upper_nibble << 4) | (lower_nibble & 0x0f);
}

