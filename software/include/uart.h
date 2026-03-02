#ifndef UARTT_HEAD
#define UART_HEAD

float uartReceive(void);

typedef union {
    float receivedFloat;
    uint8_t byteArray[4];
} uartUnion;


#endif