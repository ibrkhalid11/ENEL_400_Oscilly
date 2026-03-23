#ifndef LCD_HEAD
#define LCD_HEAD

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
void printTimeDiv(float timeDiv);
void printFreqPer(float freq, float per);
void printMaxMin(float max, float min);
void printDutyPk(float duty, float pk);
void printVoltage(float voltage, uint8_t voltScale = 0, uint8_t readingMode = 1);
void drawWave(uint8_t voltScale, uint8_t waveMode);

#endif