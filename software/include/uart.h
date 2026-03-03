#ifndef UARTT_HEAD
#define UART_HEAD

uint16_t uartReceive(void);

typedef union {
    uint16_t receivedFloat;
    uint8_t byteArray[2];
} uartUnion;


#endif