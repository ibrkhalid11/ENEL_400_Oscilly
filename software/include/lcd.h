#ifndef LCD_HEAD
#define LCD_HEAD

#include <main.h>

#define SCREEN_WIDTH 479
#define SCREEN_HEIGHT 319
#define WINDOW_HEIGHT 270
#define HEADER_HEIGHT 49
#define DIV_SIZE 30
#define MINI_DIV_SIZE 6
#define GRID_COLOUR TFT_LIGHTGREY

void lcdInit();
void drawBorders();
void drawGrid();
void drawHeader();
void drawGridLines();
void printVoltDiv(float voltDiv);
void printTimeDiv(int timeDivIndex, float timeDiv);
void printFreqPer(float freq, float per);
void printMaxMin(float max, float min);
void printAmpPk(float amp, float pk);
voltageMeasurements drawWave(uint8_t voltScale, uint16_t * voltData);
float convertVoltage(uint16_t rawVoltage);

#endif