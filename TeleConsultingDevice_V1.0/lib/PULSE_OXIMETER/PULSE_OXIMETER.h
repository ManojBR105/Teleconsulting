#ifndef PULSE_OXIMETER_H
#define PULSE_OXIMETER_H

#include <Wire.h>
#include <MAX30100_PulseOximeter.h>
#include <Arduino.h>

class PULSE_OXIMETER {
    static const SamplingRate SAMPLING_RATE = MAX30100_SAMPRATE_100HZ;
    static const LEDPulseWidth PULSE_WIDTH = MAX30100_SPC_PW_1600US_16BITS;
    static const bool HIGHRES_MODE = true;
    PulseOximeter POX;
    MAX30100 SENSOR;
    uint16_t MIN_RED;
    uint16_t MAX_RED;
    uint8_t WAVE[64];
    uint16_t NUM_SAMPLES;
    uint16_t BEAT_INT[512];
    uint16_t LAST_IBI;
    uint16_t BPM;
    float SPO2;
    uint16_t COUNT;
    uint32_t LAST_UPDATE;
    uint16_t N;
    bool DONE;
    void(*pulseOximeterCallback)();

  public:
    PULSE_OXIMETER(void (*callbackfn)());

    void reset();

    bool is_done();

    uint16_t getNUM_SAMPLES();

    uint8_t* getWAVE();

    uint16_t* getBEAT_INT();

    void get_record_data(uint16_t* bpm, uint16_t* n);

    void begin(int n_samples);

    void update();

    void sensor_update();

    void on_beat_detected();

    void draw_wave();

    void compute(float* avgIBI, float* avgBPM, float* RMSSD, float* SDNN, float* avgSPO2);

    void close();
};

#endif 