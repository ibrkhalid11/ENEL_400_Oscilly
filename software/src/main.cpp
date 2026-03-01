#include <Arduino.h>
#include <lcd.h>
#include <hardware.h>
#include <tasks.h>

void setup() {
  Serial.begin(115200);
  lcdInit();
  pinInit();
  taskCreate();

}

void loop() {

}