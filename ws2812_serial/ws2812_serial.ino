#include <FastLED.h>

#define BAUD_RATE 230400
#define SERIAL_TIMEOUT 1000

//#define LIST_MODE

#define LED_COUNT 30
#define LED_PIN 11

byte chars_to_byte(unsigned char, unsigned char);
void display_led(int);

CRGB leds[LED_COUNT];
int index;
char command[25];

void setup() {
  Serial.begin(BAUD_RATE);
  Serial.setTimeout(SERIAL_TIMEOUT);

  FastLED.addLeds<NEOPIXEL, LED_PIN>(leds, LED_COUNT);
}

void loop() {
  while (Serial.available() > 0) {
    Serial.readStringUntil(';').toCharArray(command, 25);
    if (command[0] == 'r' && command[1] == '\0') {
      FastLED.show();
    } 
    #ifdef LIST_MODE
    else if (command[0] == 'l' && command[1] == '\0') {
      Serial.println("---LIST---");
      for (int i = 0; i < LED_COUNT; i++) {
        display_led(i);
      }
    }
    #endif
    else {
      index = chars_to_byte(command[0], command[1]);
      leds[index].red   = chars_to_byte(command[2], command[3]);
      leds[index].green = chars_to_byte(command[4], command[5]);
      leds[index].blue  = chars_to_byte(command[6], command[7]);
    }
  }
}

// convert a pair of ascii hex charcters to a byte
// chars_to_byte('1', 'f') => 31
byte chars_to_byte(unsigned char upper_nibble, unsigned char lower_nibble) {
  if (upper_nibble > '9') upper_nibble -= 7;
  if (lower_nibble > '9') lower_nibble -= 7;
  return (upper_nibble << 4) | (lower_nibble & 0x0f);
}

void display_led(int i) {
  Serial.print("LED: ");Serial.print(i);
  Serial.print("  R:");Serial.print(leds[i].red);
  Serial.print("  G:");Serial.print(leds[i].green);
  Serial.print("  B:");Serial.print(leds[i].blue);
  Serial.println("");
}



