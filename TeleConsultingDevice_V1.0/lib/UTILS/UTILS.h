#ifndef UTILS_H
#define UTILS_H

#include <SPIFFS.h>
#include <FS.h>
#include <Arduino.h>


class UTILS {
  public:
    void begin();

    void create_wavHeader(char* wavHeader, int headerSize, int wavSize);

    void write_pulse_data(float avgIBI, float avgBPM, float RMSSD, float SDNN, float avgSPO2, uint16_t* BEAT_INT, uint16_t NUM_SAMPLES);

    unsigned char* get_pulse_data(size_t* readSize);

};
#endif