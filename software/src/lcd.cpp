#include <Arduino.h>
#include <SPI.h>
#include <TFT_eSPI.h>
#include <lcd.h>
#include <printf.h>

TFT_eSPI tft = TFT_eSPI();

uint16_t centerX = SCREEN_WIDTH / 2;
uint16_t centerY = SCREEN_HEIGHT / 2;

uint16_t gridHorizontal = HEADER_HEIGHT + (WINDOW_HEIGHT / 2);

char voltDivStr[50];
char timeDivStr[100];
char freqPerStr[100];
char maxMinStr[100];
char dutyPkStr[100];

void lcdInit() {
    
    tft.init();
    tft.setRotation(1);
    tft.setTextColor(TFT_WHITE);


    drawHeader();
    drawGrid();

    printVoltDiv(5);
    printTimeDiv(20);

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

void printVoltDiv(float timeDiv) {

    tft.fillRect(3, 3, 110, 45, TFT_CHARCOAL);

    snprintf(timeDivStr, sizeof(timeDivStr), "%.3f V/div", timeDiv);
    tft.setCursor(20, 20, 2);
    tft.print(timeDivStr);

}

void printTimeDiv(float voltDiv) {

    tft.fillRect(115, 3, 110, 45, TFT_CHARCOAL);

    snprintf(voltDivStr, sizeof(voltDivStr), "%.3f ms/div", voltDiv);
    tft.setCursor(120, 20, 2);
    tft.print(voltDivStr);
}

void printFreqPer(float freq, float per) {

    tft.fillRect(248, 3, 229, 45, TFT_CHARCOAL);

    snprintf(freqPerStr, sizeof(freqPerStr), "Frequency: %.3fHz   Period: %.3fs", freq, per);
    tft.setCursor(250, 25, 1);
    tft.print(freqPerStr);

}

void printMaxMin(float max, float min) {

    tft.fillRect(248, 3, 229, 45, TFT_CHARCOAL);

    snprintf(maxMinStr, sizeof(maxMinStr), "Vmax: %.3fV   Vmin: %.3fV", max, min);
    tft.setCursor(250, 25, 1);
    tft.print(maxMinStr);

}

void printDutyPk(float duty, float pk) {

    tft.fillRect(248, 3, 229, 45, TFT_CHARCOAL);

    snprintf(dutyPkStr, sizeof(dutyPkStr), "Duty cycle: %.3f%   Pk - Pk: %.3fV", duty, pk);
    tft.setCursor(250, 25, 1);
    tft.print(dutyPkStr);

}