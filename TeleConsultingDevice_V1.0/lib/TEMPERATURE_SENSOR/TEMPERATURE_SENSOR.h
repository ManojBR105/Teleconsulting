#ifndef TEMPERATURE_SENSOR_H
#define TEMPERATURE_SENSOR_H

#include <Adafruit_MLX90614.h>
#include <Wire.h>
#include <Arduino.h>

class TEMPERATURE_SENSOR {
    Adafruit_MLX90614 MLX;
    int LED_PIN;
    float AMB_TEMP[10];
    float OBJ_TEMP[10];

  public:
    TEMPERATURE_SENSOR(int led_pin); 

    void begin();

    void read();

    void get(float* ambTemp, float* objTemp);

};

#endif