#include "TEMPERATURE_SENSOR.h"

 TEMPERATURE_SENSOR::TEMPERATURE_SENSOR(int led_pin){
    LED_PIN = led_pin;
}

void TEMPERATURE_SENSOR::begin()
{
    MLX.begin();
    digitalWrite(LED_PIN, HIGH);
}

void TEMPERATURE_SENSOR::read(void (*f)(float, float))
{
    
    for (int i = 0; i < 10; i++)
    {
        digitalWrite(LED_PIN, HIGH);
        AMB_TEMP[i] = MLX.readAmbientTempF();
        OBJ_TEMP[i] = MLX.readObjectTempF();
        delay(100);
        f(AMB_TEMP[i], OBJ_TEMP[i]);
        digitalWrite(LED_PIN, LOW);
        delay(100);
    }
    digitalWrite(LED_PIN, LOW);
}

void TEMPERATURE_SENSOR::get(float *ambTemp, float *objTemp)
{
    float avg_amb = 0;
    float avg_obj = 0;
    for(int i = 0; i < 10; i++){
        avg_amb += AMB_TEMP[i];
        avg_obj += OBJ_TEMP[i];
    }
    *ambTemp = avg_amb / 10;
    *objTemp = avg_obj / 10;
}

