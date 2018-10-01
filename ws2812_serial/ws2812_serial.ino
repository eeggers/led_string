#include <FastLED.h>

#define BAUD_RATE 115200
#define SERIAL_TIMEOUT 1000

#define LED_COUNT 30
#define LED_PIN 3

CRGB leds[LED_COUNT];

/* Some stuff for parsing the serial data stream */
typedef struct {
  int led;
  byte red;
  byte green;
  byte blue;
} parsed_command_t;

// this is really dirty/hacky/inefficient... should improve this
void parse_command(parsed_command_t *r, String command) {
  r->led = command.substring(0, command.indexOf(':')).toInt();
  String rest = command.substring(command.indexOf(':')+1, command.length());
  r->red = rest.substring(0, rest.indexOf(',')).toInt();
  String rest2 = rest.substring(rest.indexOf(',')+1,rest.length());
  r->green = rest2.substring(0, rest2.indexOf(',')).toInt();
  r->blue = rest2.substring(rest2.indexOf(',')+1,rest2.length()).toInt();
}

void print_command(parsed_command_t *command) {
  Serial.println("COMMAND:");
  Serial.print(" led:   ");Serial.println(command->led);
  Serial.print(" red:   ");Serial.println(command->red);
  Serial.print(" green: ");Serial.println(command->green);
  Serial.print(" blue:  ");Serial.println(command->blue);
}
/* end */

void update_led(parsed_command_t *command) {
  leds[command->led].red   = command->red;
  leds[command->led].green = command->green;
  leds[command->led].blue  = command->blue;
  //FastLED.show();
}

void display_led(int i) {
  Serial.print("LED: ");Serial.print(i);
  Serial.print("  R:");Serial.print(leds[i].red);
  Serial.print("  G:");Serial.print(leds[i].green);
  Serial.print("  B:");Serial.print(leds[i].blue);
  Serial.println("");
}


void setup() {
  Serial.begin(BAUD_RATE);
  Serial.setTimeout(SERIAL_TIMEOUT);

  FastLED.addLeds<NEOPIXEL, LED_PIN>(leds, LED_COUNT);
}

parsed_command_t parsed_command;
String command;

void loop() {
  while (Serial.available() > 0) {
    command = Serial.readStringUntil(';');
    //Serial.println(command);
    if (command == "render") {
      FastLED.show();
    } else if (command == "fill") {
      for (int i = 0; i < LED_COUNT; i++) {
        leds[i].red   = leds[0].red;
        leds[i].green = leds[0].green;
        leds[i].blue  = leds[0].blue;
      }
    } else if (command == "list") {
      Serial.println("---LIST---");
      for (int i = 0; i < LED_COUNT; i++) {
        display_led(i);
      }
    } else {
      parse_command(&parsed_command, command);
      //print_command(&parsed_command);
      update_led(&parsed_command);
    }
  }
}




