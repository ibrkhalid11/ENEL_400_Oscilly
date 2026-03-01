#include <Arduino.h>
#include <lcd.h>
#include <hardware.h>
#include <tasks.h>

uint8_t measurement = 0;
uint8_t voltDivIndex = 0;
float voltDivModes[] = {5, 1, 0.5, 0.1};


void taskCreate() {
    xTaskCreate(
        encoderVoltTask,
        "encoderVoltTask",
        1000,
        NULL,
        1,
        NULL
    );

    xTaskCreate(
        encoderTimeTask,
        "encoderTimeTask",
        1000,
        NULL,
        1,
        NULL
    );

    xTaskCreate(
        encoderMeasTask,
        "encoderMeasTask",
        1000,
        NULL,
        1,
        NULL
    );
}

void encoderVoltTask(void * parameters) {
    while(1) {
        if(encoderVoltFlag) {
            if (millis() - encoderVoltTime >= DEBOUNCE_TIME) {

                if (s2StateVolt) {
                    if (voltDivIndex >= 3);
                    else voltDivIndex++;
                } else {
                    if (voltDivIndex <= 0);
                    else voltDivIndex--;
                }

                printVoltDiv(voltDivModes[voltDivIndex]);

                encoderVoltFlag = 0;
            }
        }

        vTaskDelay(pdTICKS_TO_MS(100));
    }
}

void encoderTimeTask(void * parameters) {
    while(1) {
        if(encoderTimeFlag) {
            if (millis() - encoderTimeTime >= DEBOUNCE_TIME) {

                if (s2StateTime) countTime++;
                else countTime--;

                Serial.print("Time encoder count: ");
                Serial.println(countTime);

                encoderTimeFlag = 0;
            }
        }

        vTaskDelay(pdTICKS_TO_MS(100));
    }
}

void encoderMeasTask(void * parameters) {
    while(1) {
        if(encoderMeasFlag) {
            if (millis() - encoderMeasTime >= DEBOUNCE_TIME) {

                if (s2StateMeas) {
                    if (measurement >= 2) measurement = 0;
                    else measurement++;
                } else {
                    if (measurement <= 0) measurement = 2;
                    else measurement--;
                }

                if (measurement == 0) printFreqPer(60, (1/(float)60));
                else if (measurement == 1) printMaxMin(5, -5);
                else if (measurement == 2) printDutyPk(80, 10);

                encoderMeasFlag = 0;
            }
        }

        vTaskDelay(pdTICKS_TO_MS(100));
    }
}