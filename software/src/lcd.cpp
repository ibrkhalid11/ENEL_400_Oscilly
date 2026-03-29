#include <Arduino.h>
#include <SPI.h>
#include <TFT_eSPI.h>
#include <lcd.h>
#include <printf.h>
#include <logo.h>

TFT_eSPI tft = TFT_eSPI();

uint16_t centerX = SCREEN_WIDTH / 2;
uint16_t centerY = SCREEN_HEIGHT / 2;

uint16_t gridHorizontal = HEADER_HEIGHT + (WINDOW_HEIGHT / 2);

char voltDivStr[100];
char timeDivStr[100];
char freqPerStr[100];
char maxMinStr[100];
char ampPkStr[100];
char voltageStr[50];

void lcdInit() {
    
    tft.init();
    tft.setRotation(1);
    tft.setTextColor(TFT_WHITE);

    tft.fillScreen(TFT_WHITE);
    tft.drawBitmap(0, 0, bitmap, 480, 320, TFT_BLACK);

    delay(2000);


    drawHeader();
    drawGrid();

    printVoltDiv(5);
    printTimeDiv(500);

    printFreqPer(60, (1/(float)60));

}

void drawGrid() {
    
    tft.fillRect(0, HEADER_HEIGHT, SCREEN_WIDTH, WINDOW_HEIGHT, TFT_BLACK);

    tft.drawWideLine(centerX, 50, centerX, SCREEN_HEIGHT, 2, GRID_COLOUR, GRID_COLOUR);
    tft.drawWideLine(0, gridHorizontal, SCREEN_WIDTH, gridHorizontal, 2, GRID_COLOUR, GRID_COLOUR);

    drawGridLines();
    
    drawBorders();

}

void drawBorders() {

    tft.drawWideLine(0, HEADER_HEIGHT, SCREEN_WIDTH, HEADER_HEIGHT, 2, TFT_WHITE, TFT_WHITE); // top
    tft.drawWideLine(0, HEADER_HEIGHT, 0, SCREEN_HEIGHT, 2, TFT_WHITE, TFT_WHITE); // left
    tft.drawWideLine(SCREEN_WIDTH, HEADER_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT, 2, TFT_WHITE, TFT_WHITE); // right 
    tft.drawWideLine(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT, 2, TFT_WHITE, TFT_WHITE); // bottom

}

void drawHeader() {

    tft.fillRect(0, 0, SCREEN_WIDTH, HEADER_HEIGHT, TFT_CHARCOAL);

    tft.drawWideLine(0, 0, SCREEN_WIDTH, 0, 2, TFT_WHITE, TFT_WHITE); // top
    tft.drawWideLine(0, 0, 0, HEADER_HEIGHT, 2, TFT_WHITE, TFT_WHITE); // left
    tft.drawWideLine(SCREEN_WIDTH, 0, SCREEN_WIDTH, HEADER_HEIGHT, 2, TFT_WHITE, TFT_WHITE); // right
    tft.drawWideLine(centerX, 0, centerX, HEADER_HEIGHT, 2, TFT_WHITE, TFT_WHITE); // divider
}

void drawGridLines() {

    // grid divisions

    for (uint16_t i = gridHorizontal; i < SCREEN_HEIGHT; i += DIV_SIZE)
        tft.drawLine(0, i, SCREEN_WIDTH, i, GRID_COLOUR);

    for (uint16_t i = gridHorizontal; i > HEADER_HEIGHT; i -= DIV_SIZE)
        tft.drawLine(0, i, SCREEN_WIDTH, i, GRID_COLOUR);

    for (uint16_t i = centerX; i < SCREEN_WIDTH; i += DIV_SIZE)
        tft.drawLine(i, HEADER_HEIGHT, i, SCREEN_HEIGHT, GRID_COLOUR);

    for (int16_t i = centerX; i > 0; i -= DIV_SIZE)
        tft.drawLine(i, HEADER_HEIGHT, i, SCREEN_HEIGHT, GRID_COLOUR);

    // smaller divisions

    for (uint16_t i = gridHorizontal; i < SCREEN_HEIGHT; i += MINI_DIV_SIZE)
        tft.drawLine(centerX - 3, i, centerX + 3, i, GRID_COLOUR);

    for (uint16_t i = gridHorizontal; i > HEADER_HEIGHT; i -= MINI_DIV_SIZE)
        tft.drawLine(centerX - 3, i, centerX + 3, i, GRID_COLOUR);

    for (uint16_t i = centerX; i < SCREEN_WIDTH; i += MINI_DIV_SIZE)
        tft.drawLine(i, gridHorizontal - 3, i, gridHorizontal + 3, GRID_COLOUR);

    for (int16_t i = centerX; i > 0; i -= MINI_DIV_SIZE)
        tft.drawLine(i, gridHorizontal - 3, i, gridHorizontal + 3, GRID_COLOUR);
    
}

void printVoltDiv(float voltDiv) {

    tft.fillRect(3, 3, 110, 45, TFT_CHARCOAL);

    snprintf(voltDivStr, sizeof(voltDivStr), "%.3f V/div", voltDiv);
    tft.setTextColor(TFT_WHITE, TFT_CHARCOAL);
    tft.setCursor(20, 20, 2);
    tft.print(voltDivStr);

}

void printTimeDiv(float timeDiv) {

    tft.fillRect(115, 3, 110, 45, TFT_CHARCOAL);

    snprintf(timeDivStr, sizeof(timeDivStr), "%.3f ms/div", timeDiv);
    tft.setTextColor(TFT_WHITE, TFT_CHARCOAL);
    tft.setCursor(120, 20, 2);
    tft.print(timeDivStr);
}

void printFreqPer(float freq, float per) {

    tft.fillRect(248, 3, 229, 45, TFT_CHARCOAL);

    snprintf(freqPerStr, sizeof(freqPerStr), "Frequency: %.3fHz   Period: %.3fs", freq, per);
    tft.setTextColor(TFT_WHITE, TFT_CHARCOAL);
    tft.setCursor(250, 25, 1);
    tft.print(freqPerStr);

}

void printMaxMin(float max, float min) {

    tft.fillRect(248, 3, 229, 45, TFT_CHARCOAL);

    snprintf(maxMinStr, sizeof(maxMinStr), "Vmax: %.3fV   Vmin: %.3fV", max, min);
    tft.setTextColor(TFT_WHITE, TFT_CHARCOAL);
    tft.setCursor(250, 25, 1);
    tft.print(maxMinStr);

}

void printAmpPk(float amp, float pk) {

    tft.fillRect(248, 3, 229, 45, TFT_CHARCOAL);

    snprintf(ampPkStr, sizeof(ampPkStr), "Amplitude: %.3fV   Pk-Pk: %.3fV", amp, pk);
    tft.setTextColor(TFT_WHITE, TFT_CHARCOAL);
    tft.setCursor(250, 25, 1);
    tft.print(ampPkStr);

}

void drawWave(uint8_t voltScale, uint16_t * voltData) {
    drawGrid();
    uint16_t pixPerVolt = 0;

    if (voltScale == 0) pixPerVolt = 6;
    else if (voltScale == 1) pixPerVolt = 30;
    else if (voltScale == 2) pixPerVolt = 60;
    else if (voltScale == 3) pixPerVolt = 300;

    for (uint16_t i = 0; i < 480; i++) {
        if (i > 0) {

            float y = gridHorizontal - (convertVoltage(voltData[i]) * pixPerVolt);
            float lastY = gridHorizontal - (convertVoltage(voltData[i - 1]) * pixPerVolt);

            if ((y > HEADER_HEIGHT) && (lastY > HEADER_HEIGHT)) tft.drawWideLine(i - 1, lastY, i, y, 3, TFT_YELLOW, TFT_YELLOW);

        } else {
            float y = gridHorizontal - (convertVoltage(voltData[i]) * pixPerVolt);
            if ((y > HEADER_HEIGHT) && (y < SCREEN_HEIGHT)) tft.drawSpot(i, y, 1, TFT_YELLOW, TFT_YELLOW);
        }
    }

    
}

float convertVoltage(uint16_t rawVoltage) {
    float scaledVoltage = (((float)rawVoltage / 1000) - 3) * 5;
    return scaledVoltage; 
}