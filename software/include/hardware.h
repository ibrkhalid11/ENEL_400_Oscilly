#ifndef HARDWARE_HEAD
#define HARDWARE_HEAD

#include <Arduino.h>

#define DEBOUNCE_TIME 100

#define KEY_VOLT 36
#define S2_VOLT 39
#define S1_VOLT 34

#define KEY_TIME 35
#define S2_TIME 32
#define S1_TIME 33

#define KEY_MEAS 25
#define S2_MEAS 26
#define S1_MEAS 27

void pinInit();

// interrupts

void btnVoltISR(void);
void btnTimeISR(void);
void btnMeasISR(void);
void enVoltISR(void);
void enTimeISR(void);
void enMeasISR(void);

// extern uint8_t encoderVoltFlag;
// extern uint8_t encoderTimeFlag;
// extern uint8_t encoderMeasFlag;

// extern uint32_t encoderVoltTime;
// extern uint32_t encoderTimeTime;
// extern uint32_t encoderMeasTime;

// extern int8_t s2StateVolt;
// extern int8_t s2StateTime;
// extern int8_t s2StateMeas;

typedef struct {
    uint8_t enFlag;
    uint8_t btnFlag;
    uint8_t s2State;
    uint32_t timestamp;

} encoder;

extern encoder voltEn;
extern encoder timeEn;
extern encoder measEn;

#endif