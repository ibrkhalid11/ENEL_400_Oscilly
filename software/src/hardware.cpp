#include <Arduino.h>
#include <hardware.h>

encoder voltEn = {0, 0, 0, 0, 0};
encoder timeEn = {0, 0, 0, 0, 0};
encoder measEn = {0, 0, 0, 0, 0};

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

    pinMode(MCU_READY, OUTPUT);
    digitalWrite(MCU_READY, 1);

    pinMode(FPGA_READY, INPUT);

    // attachInterrupt(KEY_VOLT, btnVoltISR, FALLING);
    // attachInterrupt(KEY_TIME, btnTimeISR, FALLING);
    attachInterrupt(KEY_MEAS, btnMeasISR, RISING);
    // attachInterrupt(KEY_VOLT, btnVoltISR, RISING);

    attachInterrupt(S1_VOLT, enVoltISR, RISING);
    attachInterrupt(S1_TIME, enTimeISR, RISING);
    attachInterrupt(S1_MEAS, enMeasISR, RISING);
    
    // attachInterrupt(FPGA_READY, fpgaReadyISR, FALLING);
    
}

// interrupts

void IRAM_ATTR btnVoltISR(void) {

    digitalWrite(MCU_READY, 1);

}

void IRAM_ATTR btnTimeISR(void) {

}

void IRAM_ATTR btnMeasISR(void) {

    if (!measEn.btnFlag) {
        measEn.btnTimestamp = millis();
        measEn.btnFlag = 1;
    }

}

void IRAM_ATTR enVoltISR(void) {

    if (!voltEn.enFlag) {
        voltEn.enTimestamp = millis();
        voltEn.s2State = digitalRead(S2_VOLT);
        voltEn.enFlag = 1;
    }

}

void IRAM_ATTR enTimeISR(void) {

    if (!timeEn.enFlag) {
        timeEn.enTimestamp = millis();
        timeEn.s2State = digitalRead(S2_TIME);
        timeEn.enFlag = 1;
    }
    
}

void IRAM_ATTR enMeasISR(void) {
    
    if (!measEn.enFlag) {
        measEn.enTimestamp = millis();
        measEn.s2State = digitalRead(S2_MEAS);
        measEn.enFlag = 1;
    }

}

void IRAM_ATTR fpgaReadyISR(void) {
    digitalWrite(MCU_READY, 0);
}