#include <Adafruit_NeoPixel.h>
#include <EEPROM.h>

#define BAUD_RATE 115200
#define SERIAL_TIMEOUT 1000

#define LED_COUNT 256
#define LED_PIN 5

#define PERIODIC_REFRESH_INTERVAL 1000000 // loop iterations

char command[25];
uint32_t periodic_refresh_counter = 0;


Adafruit_NeoPixel strip(LED_COUNT, LED_PIN, NEO_GRBW + NEO_KHZ800);

void setup() {
  Serial.begin(BAUD_RATE);
  Serial.setTimeout(SERIAL_TIMEOUT);

  strip.begin();
  strip.show();
  strip.setBrightness(255);
  eeprom_load();
  strip.show();
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
        case 'f': // FILL
          fill();
          break;   
      }
    } else {      // SET LED
      set_led(command);
    }
  }
  // hack 
  if (++periodic_refresh_counter == PERIODIC_REFRESH_INTERVAL) {
    periodic_refresh_counter = 0;
    render();
  }
}

void render() {
  strip.show();
}

void clear() {
  strip.fill(0);
  strip.show();
}

void fill() {
  strip.fill(strip.getPixelColor(0));
}

void dump() {
  Serial.println("---BEGIN DUMP---");
  for (int i = 0; i < LED_COUNT; i++) {
    Serial.print(i, HEX);Serial.print(":");
    Serial.print(strip.getPixelColor(i), HEX);
    Serial.println(";");
  }
  Serial.println("---END DUMP---");
}


void eeprom_save() {
  for (uint16_t i = 0; i < LED_COUNT; i++) {
    uint32_t led = strip.getPixelColor(i);
    EEPROM.write(4 * i + 0, (led & 0xff000000) >> 24);
    EEPROM.write(4 * i + 1, (led & 0x00ff0000) >> 16);
    EEPROM.write(4 * i + 2, (led & 0x0000ff00) >> 8);
    EEPROM.write(4 * i + 3, (led & 0x000000ff));
  }
}

void eeprom_load() {
  for (uint16_t i = 0; i < LED_COUNT; i++) {
    uint32_t led = 0;
    led |= (uint32_t)EEPROM.read(4 * i) << 24;
    led |= (uint32_t)EEPROM.read(4 * i + 1) << 16;
    led |= (uint32_t)EEPROM.read(4 * i + 2) << 8;
    led |= (uint32_t)EEPROM.read(4 * i + 3);
    strip.setPixelColor(i, led);
  }
}

void set_led(char *command) {
  strip.setPixelColor(
    chars_to_byte(command[0], command[1]), // index
    chars_to_byte(command[2], command[3]), // r
    chars_to_byte(command[4], command[5]), // g
    chars_to_byte(command[6], command[7]), // b
    chars_to_byte(command[8], command[9]) // w
  );
}


// convert a pair of ascii hex charcters to a byte
// chars_to_byte('1', 'f') => 31
byte chars_to_byte(unsigned char upper_nibble, unsigned char lower_nibble) {
  if (upper_nibble > '9') upper_nibble -= 7;
  if (lower_nibble > '9') lower_nibble -= 7;
  return (upper_nibble << 4) | (lower_nibble & 0x0f);
}

