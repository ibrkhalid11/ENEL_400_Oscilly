#ifndef MAIN_HEAD
#define MAIN_HEAD

#include <Arduino.h>

extern uint8_t currentMode;

typedef union {
    uint16_t measurement;
    uint8_t receivedArray[2];
} measurementUnion;

typedef union {
    uint16_t voltData[480];
    uint8_t receivedArray[960];
} voltageUnion;
  

#endif