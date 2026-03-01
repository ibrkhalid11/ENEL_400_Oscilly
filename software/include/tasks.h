#ifndef TASK_HEAD
#define TASK_HEAD

#include <Arduino.h>

void taskCreate();

void encoderVoltTask(void * parameters);
void encoderTimeTask(void * parameters);
void encoderMeasTask(void * parameters);

#endif