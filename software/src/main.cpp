#include <Arduino.h>
#include <lcd.h>
#include <hardware.h>
#include <tasks.h>
#include <uart.h>

uint8_t measurement = 0;
uint8_t voltDivIndex = 0;
uint8_t timeDivIndex = 0;
float voltDivModes[] = {5, 1, 0.5, 0.1};
float timeDivModes[] = {500, 100, 50, 10, 5, 1, 0.5, 0.1, 0.05, 0.01, 0.005, 0.001};

QueueHandle_t uartQueue;
SemaphoreHandle_t displayMutex;

HardwareSerial fpga(2);

void setup() {
  
  fpga.begin(115200, SERIAL_8N1, 13, 12, false, 4096);
  Serial.begin(9600);
  lcdInit();
  pinInit();

  uartQueue = xQueueCreate(5, sizeof(float));
  displayMutex = xSemaphoreCreateMutex();
  taskCreate();

}

void loop() {

}

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

  xTaskCreate(
      uartTask,
      "uartTask",
      100000,
      NULL,
      3,
      NULL
  );

  xTaskCreate(
      voltageUpdateTask,
      "voltageUpdateTask",
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

              if(xSemaphoreTake(displayMutex, 0) == pdTRUE) {
            
                  if (voltEn.s2State) {
                      if (voltDivIndex >= 3);
                      else voltDivIndex++;
                  } else {
                      if (voltDivIndex <= 0);
                      else voltDivIndex--;
                  }

                  printVoltDiv(voltDivModes[voltDivIndex]);

                  voltEn.enFlag = 0;

                  xSemaphoreGive(displayMutex);
              }
          }
      }

      vTaskDelay(pdTICKS_TO_MS(50));
  }
}

void encoderTimeTask(void * parameters) {
  while(1) {
      if(timeEn.enFlag) {
          if (millis() - timeEn.timestamp >= DEBOUNCE_TIME) {

              if(xSemaphoreTake(displayMutex, 0) == pdTRUE) {

                  if (timeEn.s2State) {
                      if (timeDivIndex >= 11);
                      else timeDivIndex++;
                  } else {
                      if (timeDivIndex <= 0);
                      else timeDivIndex--;
                  }

                  printTimeDiv(timeDivModes[timeDivIndex]);

                  timeEn.enFlag = 0;

                  xSemaphoreGive(displayMutex);
              }
          }
      }

      vTaskDelay(pdTICKS_TO_MS(50));
  }
}

void encoderMeasTask(void * parameters) {
    while(1) {
        if(measEn.enFlag) {
            if (millis() - measEn.timestamp >= DEBOUNCE_TIME) {

                if (xSemaphoreTake(displayMutex, 0) == pdTRUE) {

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

                    xSemaphoreGive(displayMutex);
                }
            }
        }

        vTaskDelay(pdTICKS_TO_MS(50));
    }
}

void uartTask (void * parameters) {

    while(1) {
        if (fpga.available() >= 4) {
            float receivedFloat;
            receivedFloat = uartReceive();
    
            Serial.println(receivedFloat, 5);

            if (xQueueSend(uartQueue, &receivedFloat, 0) != pdTRUE);
        }

        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

void voltageUpdateTask(void * parameters) {
    while(1) {
        if (xSemaphoreTake(displayMutex, 0) == pdTRUE) {
            float receivedFloat = 0;
            if (xQueueReceive(uartQueue, &receivedFloat, 0) == pdPASS) {

                printVoltage(receivedFloat);

            }

            xSemaphoreGive(displayMutex);
            
        }

        vTaskDelay(pdMS_TO_TICKS(500));
    }
}

float uartReceive(void) {

    uartUnion receivedBytes;
    fpga.readBytes(receivedBytes.byteArray, 4);

    return receivedBytes.receivedFloat;

}