#include <Arduino.h>
#include <lcd.h>
#include <hardware.h>
#include <tasks.h>
#include <uart.h>

uint8_t voltReadingMode = 1;
uint8_t measurement = 0;
uint8_t voltDivIndex = 0;
uint8_t timeDivIndex = 0;
float voltDivModes[] = {5, 1, 0.5, 0.1};
float timeDivModes[] = {500, 100, 50, 10, 5, 1, 0.5, 0.1, 0.05, 0.01, 0.005, 0.001};

QueueHandle_t uartQueue;
SemaphoreHandle_t displayMutex;
SemaphoreHandle_t measMutex;

uint8_t scrapBuffer[1024];
voltageUnion voltUnion;
measurementUnion perUnion;
measurementUnion vMaxUnion;
measurementUnion vMinUnion;
measurementUnion pkToPkUnion;

float voltData[480];
float freq = 0;
float per = 0;
float vMax = 0;
float vMin = 0;
float duty = 0;
float pkToPk = 0;

uint8_t dataReadyFlag = 0;
uint8_t rxReadyFlag = 1;


HardwareSerial fpga(2);

void setup() {
  
  fpga.setRxBufferSize(1024);
  fpga.begin(115200, SERIAL_8N1, 13, 12, false, 4096);
  Serial.begin(9600);
  lcdInit();
  pinInit();

  uartQueue = xQueueCreate(5, sizeof(float));
  displayMutex = xSemaphoreCreateMutex();
  measMutex = xSemaphoreCreateMutex();
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
      10000,
      NULL,
      3,
      NULL
  );

  xTaskCreate(
      waveformUpdateTask,
      "waveformUpdateTask",
      10000,
      NULL,
      4,
      NULL
  );
}

void encoderVoltTask(void * parameters) {
  while(1) {
      if(voltEn.enFlag) {
          if (millis() - voltEn.enTimestamp >= DEBOUNCE_TIME) {

              if(xSemaphoreTake(displayMutex, 0) == pdTRUE) {
            
                  if (voltEn.s2State) {
                      if (voltDivIndex >= 3);
                      else voltDivIndex++;
                  } else {
                      if (voltDivIndex <= 0);
                      else voltDivIndex--;
                  }

                  printVoltDiv(voltDivModes[voltDivIndex]);
                  drawWave(voltDivIndex, voltUnion.voltData);

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
          if (millis() - timeEn.enTimestamp >= DEBOUNCE_TIME) {

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

      vTaskDelay(pdTICKS_TO_MS(10));
  }
}

void encoderMeasTask(void * parameters) {
    while(1) {
        if(measEn.enFlag) {
            if (millis() - measEn.enTimestamp >= DEBOUNCE_TIME) {

                if ((xSemaphoreTake(displayMutex, 0) == pdTRUE) && (xSemaphoreTake(measMutex, 0) == pdTRUE)) {

                    if (measEn.s2State) {
                        if (measurement >= 2) measurement = 0;
                        else measurement++;
                    } else {
                        if (measurement <= 0) measurement = 2;
                        else measurement--;
                    }

                    if (measurement == 0) printFreqPer(freq, per);
                    else if (measurement == 1) printMaxMin(vMax, vMin);
                    else if (measurement == 2) printDutyPk(duty, pkToPk);

                    measEn.enFlag = 0;

                    xSemaphoreGive(displayMutex);
                    xSemaphoreGive(measMutex);
                }
            }
        }

        vTaskDelay(pdTICKS_TO_MS(100));
    }
}

void uartTask (void * parameters) {

    while(1) {
        if (!dataReadyFlag) {
            if (fpga.available() >= 968) {
                
                fpga.readBytes(voltUnion.receivedArray, 960);
                fpga.readBytes(perUnion.receivedArray, 2);
                fpga.readBytes(vMaxUnion.receivedArray, 2);
                fpga.readBytes(vMinUnion.receivedArray, 2);
                fpga.readBytes(pkToPkUnion.receivedArray, 2);
                fpga.readBytes(scrapBuffer, 1024);

                dataReadyFlag = 1;

            }

            // if (fpga.available() >= 200) {
            //     Serial.println(fpga.read());
            //     dataReadyFlag = 1;
            // }
        }

        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

void waveformUpdateTask(void * parameters) {
    while(1) {
        
        if (dataReadyFlag) {
            if ((xSemaphoreTake(displayMutex, 0) == pdTRUE) && (xSemaphoreTake(measMutex, 0) == pdTRUE)) {

                per = convertVoltage(perUnion.measurement);
                freq = (float) 1 / per;
                vMax = convertVoltage(vMaxUnion.measurement);
                vMin = convertVoltage(vMinUnion.measurement);
                pkToPk = convertVoltage(pkToPkUnion.measurement);
                
                drawWave(voltDivIndex, voltUnion.voltData);

                if (measurement == 0) printFreqPer(freq, per);
                else if (measurement == 1) printMaxMin(vMax, vMin);
                else if (measurement == 2) printDutyPk(duty, pkToPk);

                dataReadyFlag = 0;
                digitalWrite(MCU_READY, 1);
                xSemaphoreGive(displayMutex);
                xSemaphoreGive(measMutex);
                
            }

        }

        vTaskDelay(pdMS_TO_TICKS(100));
   }
}