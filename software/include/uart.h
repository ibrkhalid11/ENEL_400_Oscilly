#ifndef UARTT_HEAD
#define UART_HEAD

typedef union {
    uint16_t measurement;
    uint8_t receivedArray[2];
} measurementUnion;

typedef union {
    uint16_t voltData[480];
    uint8_t receivedArray[960];
} voltageUnion;

#endif