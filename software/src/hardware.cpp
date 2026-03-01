#include <Arduino.h>
#include <hardware.h>

encoder voltEn = {0, 0, 0, 0};
encoder timeEn = {0, 0, 0, 0};
encoder measEn = {0, 0, 0, 0};

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

    // attachInterrupt(KEY_VOLT, buttonPressVolt, FALLING);
    // attachInterrupt(KEY_TIME, buttonPressTime, FALLING);
    // attachInterrupt(KEY_MEAS, buttonPressMeas, FALLING);

    attachInterrupt(S1_VOLT, enVoltISR, RISING);
    attachInterrupt(S1_TIME, enTimeISR, RISING);
    attachInterrupt(S1_MEAS, enMeasISR, RISING);

    
}

// interrupts

void IRAM_ATTR btnVoltISR(void) {

}

void IRAM_ATTR btnTimeISR(void) {

}

void IRAM_ATTR btnMeasISR(void) {

}

void IRAM_ATTR enVoltISR(void) {

    if (!voltEn.enFlag) {
        voltEn.timestamp = millis();
        voltEn.s2State = digitalRead(S2_VOLT);
        voltEn.enFlag = 1;
    }

}

void IRAM_ATTR enTimeISR(void) {

    if (!timeEn.enFlag) {
        timeEn.timestamp = millis();
        timeEn.s2State = digitalRead(S2_TIME);
        timeEn.enFlag = 1;
    }
    
}

void IRAM_ATTR enMeasISR(void) {
    
    if (!measEn.enFlag) {
        measEn.timestamp = millis();
        measEn.s2State = digitalRead(S2_MEAS);
        measEn.enFlag = 1;
    }

}