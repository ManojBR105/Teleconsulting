#ifndef SPI_OLED_H
#define SPI_OLED_H

#include <bitmaps.h>
#include <SPI.h>
#include <Arduino.h>
#include <U8g2lib.h>

class SPI_OLED
{
    const unsigned char* logo = myBitmap;
    const unsigned char* bt = myBtLogo;
    const unsigned char* mobile = mobileLogo;
    const unsigned char* rec = myRecLogo;
    const unsigned char* file = fileLogo;
    const unsigned char* upload = uploadLogo;
    const unsigned char* done = sentLogo;
    U8G2_SSD1306_128X64_NONAME_F_4W_HW_SPI* display;

  public:

    SPI_OLED(int res, int dc, int cs);

    ~SPI_OLED();

    void begin();

    void wait_screen();

    void selection_screen();

    void pre_record_screen(int param);

    void record_screen(float progress);

    void record_screen(uint16_t bpm, uint16_t n, uint8_t* wave, uint16_t num_samples);

    void result_screen(float avgIBI, float avgBPM, float RMSSD, float SDNN, float avgSPO2);

    void finished_record_screen();

    void sent_screen(int param);
};

#endif