#include "PULSE_OXIMETER.h"

PULSE_OXIMETER::PULSE_OXIMETER(void (*callbackfn)())
{
    pulseOximeterCallback = callbackfn;
}

void PULSE_OXIMETER::reset()
{
    for (int i = 0; i < 512; i++)
    {
        BEAT_INT[i] = 0;
        if (i < 64)
            WAVE[i] = 0;
    }
    MIN_RED = 65535;
    MAX_RED = 1;
    N = 0;
    COUNT = 0;
    LAST_UPDATE = 0;
    BPM = 0;
    SPO2 = 0;
    LAST_IBI = 0;
    DONE = false;
}

bool PULSE_OXIMETER::is_done()
{
    return DONE;
}

uint16_t PULSE_OXIMETER::getNUM_SAMPLES()
{
    return NUM_SAMPLES;
}

uint8_t *PULSE_OXIMETER::getWAVE()
{
    return WAVE;
}

uint16_t *PULSE_OXIMETER::getBEAT_INT()
{
    return BEAT_INT;
}

void PULSE_OXIMETER::get_record_data(uint16_t *bpm, uint16_t *n)
{
    *bpm = BPM;
    *n = N;
}

void PULSE_OXIMETER::begin(int n_samples)
{
    Serial.print("Initializing pulse oximeter..");
    if (!POX.begin())
    {
        Serial.println("FAILED");
        while (1)
            ;
    }
    POX.setIRLedCurrent(MAX30100_LED_CURR_7_6MA);
    POX.setOnBeatDetectedCallback(pulseOximeterCallback);
    if (!SENSOR.begin())
    {
        Serial.println("FAILED");
        for (;;)
            ;
    }
    else
    {
        Serial.println("SUCCESS");
    }
    SENSOR.setMode(MAX30100_MODE_SPO2_HR);
    SENSOR.setLedsPulseWidth(PULSE_WIDTH);
    SENSOR.setSamplingRate(SAMPLING_RATE);
    SENSOR.setHighresModeEnabled(HIGHRES_MODE);
    NUM_SAMPLES = n_samples;
    reset();
}

void PULSE_OXIMETER::update()
{
    //Serial.print("Period: ");
    //Serial.println(micros() - LAST_UPDATE);
    POX.update();
    SENSOR.update();
    LAST_UPDATE = micros();
    draw_wave();
}

void PULSE_OXIMETER::sensor_update()
{
    SENSOR.update();
}

void PULSE_OXIMETER::on_beat_detected()
{
    uint16_t IBI = POX.getHeartBeatInterval();

    if (COUNT > 5)
    {
        if (400 < IBI && IBI < 1200)
        {
            BEAT_INT[N] = IBI;
            BPM = 60000 / IBI;
            SPO2 += POX.getSpO2();
            N++;
            if (N >= NUM_SAMPLES)
                DONE = true;
        }
        else
        {
            COUNT = 0;
        }
    }
    LAST_IBI = IBI;
    COUNT++;
}

void PULSE_OXIMETER::draw_wave()
{
    uint16_t red, ir;
    if ((MAX_RED - MIN_RED) >= 500)
    {
        MIN_RED = 65535;
        MAX_RED = 1;
    }
    while (SENSOR.getRawValues(&ir, &red))
    {
        if (red > MAX_RED)
            MAX_RED = red;
        else if (red < MIN_RED)
            MIN_RED = red;
        if (MIN_RED >= MAX_RED)
            return;
        uint8_t amp = map(red, MIN_RED, MAX_RED, 1, 40);
        for (int i = 0; i < 63; i++)
            WAVE[i] = WAVE[i + 1];
        WAVE[63] = constrain(amp, 1, 40);
    }
}

void PULSE_OXIMETER::compute(float *avgIBI, float *avgBPM, float *RMSSD, float *SDNN, float *avgSPO2)
{
    uint32_t sum = 0;
    uint32_t SDNNsum = 0;
    uint32_t RMSSDsum = 0;
    for (int i = 0; i < NUM_SAMPLES; i++)
        sum += BEAT_INT[i];
    *avgIBI = (float)sum / NUM_SAMPLES;
    *avgBPM = *avgIBI / 1000;
    *avgBPM = 60 / *avgBPM;
    for (int i = 0; i < NUM_SAMPLES; i++)
    {
        SDNNsum += (BEAT_INT[i] - *avgIBI) * (BEAT_INT[i] - *avgIBI);
        if (i)
            RMSSDsum += (BEAT_INT[i - 1] - BEAT_INT[i]) * (BEAT_INT[i - 1] - BEAT_INT[i]);
    }
    *SDNN = sqrt(SDNNsum / NUM_SAMPLES);
    *RMSSD = sqrt(RMSSDsum / (NUM_SAMPLES - 1));
    *avgSPO2 = SPO2 / NUM_SAMPLES;
}

void PULSE_OXIMETER::close()
{
    POX.shutdown();
    SENSOR.shutdown();
}