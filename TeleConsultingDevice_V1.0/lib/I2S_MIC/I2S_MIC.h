#ifndef I2S_MIC_H
#define I2S_MIC_H

#include <freertos.h>
#include <driver/i2s.h>

class I2S_MIC
{
    int I2S_WS;
    int I2S_SD;
    int I2S_SCK;
    int I2S_PORT;
    int I2S_SAMPLE_RATE;
    int I2S_SAMPLE_BITS;
    int I2S_RECORD_SIZE_PER_SEC;
    static const int I2S_READ_SIZE = 256;

  public:
    

    I2S_MIC(int ws, int sd, int sck, int port, int sample_rate, int sample_bits);

    void begin();

    void read(uint16_t* dest_addr, size_t* bytes_read);

    int getI2S_RECORD_SIZE_PER_SEC();
    int getI2S_READ_SIZE();
};

#endif
