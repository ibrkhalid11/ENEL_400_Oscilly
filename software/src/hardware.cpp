#include <Arduino.h>
#include <hardware.h>

uint8_t encoderVoltFlag = 0;
uint8_t encoderTimeFlag = 0;
uint8_t encoderMeasFlag = 0;

uint32_t encoderVoltTime = 0;
uint32_t encoderTimeTime = 0;
uint32_t encoderMeasTime = 0;

int8_t countVolt = 0;
int8_t countTime = 0;
int8_t countMeas = 0;

int8_t s2StateVolt = 0;
int8_t s2StateTime = 0;
int8_t s2StateMeas = 0;


void pinInit() {

    pinMode(S1_VOLT, 1);
    pinMode(S2_VOLT, 1);
    pinMode(KEY_VOLT, 1);

    pinMode(S1_TIME, 1);
    pinMode(S2_TIME, 1);
    pinMode(KEY_TIME, 1);

    pinMode(S1_MEAS, 1);
    pinMode(S2_MEAS, 1);
    pinMode(KEY_MEAS, 1);

    attachInterrupt(KEY_VOLT, buttonPressVolt, FALLING);
    attachInterrupt(KEY_TIME, buttonPressTime, FALLING);
    attachInterrupt(KEY_MEAS, buttonPressMeas, FALLING);

    attachInterrupt(S1_VOLT, encoderVolt, RISING);
    attachInterrupt(S1_TIME, encoderTime, RISING);
    attachInterrupt(S1_MEAS, encoderMeas, RISING);

    
}

// interrupts

void IRAM_ATTR buttonPressVolt(void) {

}

void IRAM_ATTR buttonPressTime(void) {

}

void IRAM_ATTR buttonPressMeas(void) {

}

void IRAM_ATTR encoderVolt(void) {

    if (!encoderVoltFlag) {
        encoderVoltTime = millis();
        s2StateVolt = digitalRead(S2_VOLT);
        encoderVoltFlag = 1;
    }

}

void IRAM_ATTR encoderTime(void) {

    if (!encoderTimeFlag) {
        encoderTimeTime = millis();
        s2StateTime = digitalRead(S2_TIME);
        encoderTimeFlag = 1;
    }
    
}

void IRAM_ATTR encoderMeas(void) {
    
    if (!encoderMeasFlag) {
        encoderMeasTime = millis();
        s2StateMeas = digitalRead(S2_MEAS);
        encoderMeasFlag = 1;
    }

}