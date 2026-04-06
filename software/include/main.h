#ifndef MAIN_HEAD
#define MAIN_HEAD

#include <Arduino.h>

extern volatile uint8_t currentMode;

typedef union {
    uint16_t measurement;
    uint8_t receivedArray[2];
} measurementUnion;

typedef union {
    uint16_t voltData[480];
    uint8_t receivedArray[960];
} voltageUnion;

typedef struct {
    float vMax;
    float vMin;
} voltageMeasurements;
  

#endif