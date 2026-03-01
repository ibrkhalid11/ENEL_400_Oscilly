#include <Arduino.h>
#include <lcd.h>
#include <hardware.h>
#include <tasks.h>

uint8_t measurement = 0;
uint8_t voltDivIndex = 0;
uint8_t timeDivIndex = 0;
float voltDivModes[] = {5, 1, 0.5, 0.1};
float timeDivModes[] = {500, 100, 50, 10, 5, 1, 0.5, 0.1, 0.05, 0.01, 0.005, 0.001};


void taskCreate() {
    xTaskCreate(
        encoderVoltTask,
        "encoderVoltTask",
        10000,
        NULL,
        1,
        NULL
    );

    xTaskCreate(
        encoderTimeTask,
        "encoderTimeTask",
        10000,
        NULL,
        1,
        NULL
    );

    xTaskCreate(
        encoderMeasTask,
        "encoderMeasTask",
        10000,
        NULL,
        1,
        NULL
    );
}

void encoderVoltTask(void * parameters) {
    while(1) {
        if(voltEn.enFlag) {
            if (millis() - voltEn.timestamp >= DEBOUNCE_TIME) {

                if (voltEn.s2State) {
                    if (voltDivIndex >= 3);
                    else voltDivIndex++;
                } else {
                    if (voltDivIndex <= 0);
                    else voltDivIndex--;
                }

                printVoltDiv(voltDivModes[voltDivIndex]);

                voltEn.enFlag = 0;
            }
        }

        vTaskDelay(pdTICKS_TO_MS(100));
    }
}

void encoderTimeTask(void * parameters) {
    while(1) {
        if(timeEn.enFlag) {
            if (millis() - timeEn.timestamp >= DEBOUNCE_TIME) {

                if (timeEn.s2State) {
                    if (timeDivIndex >= 11);
                    else timeDivIndex++;
                } else {
                    if (timeDivIndex <= 0);
                    else timeDivIndex--;
                }

                printTimeDiv(timeDivModes[timeDivIndex]);

                timeEn.enFlag = 0;
            }
        }

        vTaskDelay(pdTICKS_TO_MS(100));
    }
}

void encoderMeasTask(void * parameters) {
    while(1) {
        if(measEn.enFlag) {
            if (millis() - measEn.timestamp >= DEBOUNCE_TIME) {

                if (measEn.s2State) {
                    if (measurement >= 2) measurement = 0;
                    else measurement++;
                } else {
                    if (measurement <= 0) measurement = 2;
                    else measurement--;
                }

                if (measurement == 0) printFreqPer(60, (1/(float)60));
                else if (measurement == 1) printMaxMin(5, -5);
                else if (measurement == 2) printDutyPk(80, 10);

                measEn.enFlag = 0;
            }
        }

        vTaskDelay(pdTICKS_TO_MS(100));
    }
}