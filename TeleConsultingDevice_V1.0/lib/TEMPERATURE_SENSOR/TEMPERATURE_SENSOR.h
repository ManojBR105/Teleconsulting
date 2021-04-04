#ifndef TEMPERATURE_SENSOR_H
#define TEMPERATURE_SENSOR_H

#include <Adafruit_MLX90614.h>
#include <Wire.h>
#include <Arduino.h>

class TEMPERATURE_SENSOR {
    Adafruit_MLX90614 MLX;
    static const int LED_PIN = 27;
    float AMB_TEMP[10];
    float OBJ_TEMP[10];

  public:
    void begin();

    void read();

    void get(float* ambTemp, float* objTemp);

    void close();
};

#endif