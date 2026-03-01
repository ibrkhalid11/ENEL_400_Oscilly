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

void buttonPressVolt(void);
void buttonPressTime(void);
void buttonPressMeas(void);
void encoderVolt(void);
void encoderTime(void);
void encoderMeas(void);

extern uint8_t encoderVoltFlag;
extern uint8_t encoderTimeFlag;
extern uint8_t encoderMeasFlag;

extern uint32_t encoderVoltTime;
extern uint32_t encoderTimeTime;
extern uint32_t encoderMeasTime;

extern int8_t countVolt;
extern int8_t countTime;
extern int8_t countMeas;

extern int8_t s2StateVolt;
extern int8_t s2StateTime;
extern int8_t s2StateMeas;

#endif