#include "SPI_OLED.h"

SPI_OLED::SPI_OLED(int res, int dc, int cs)
{
    display = new U8G2_SSD1306_128X64_NONAME_F_4W_HW_SPI(U8G2_R2, cs, dc, res);
}

SPI_OLED::~SPI_OLED()
{
    delete display;
}

void SPI_OLED::begin()
{
    display->begin();
    display->clearBuffer();
    display->drawXBM(0, 0, 128, 64, logo);
    display->sendBuffer();
    delay(2000);
    display->clear();
    display->setFont(u8g2_font_ncenB08_tr);
    display->drawStr(20, 24, "Tele Consulting");
    display->drawStr(42, 42, "Device");
    display->sendBuffer();
    delay(2000);
    display->clear();
}

void SPI_OLED::wait_screen()
{
    display->clearBuffer();
    display->drawBitmap(48, 20, 4, 40, bt);
    display->drawStr(0, 10, " No Device Connected ");
    display->sendBuffer();
}

void SPI_OLED::selection_screen()
{
    display->clearBuffer();
    display->drawBitmap(40, 20, 6, 40, mobile);
    display->drawStr(0, 10, "Click Start Recodrding");
    display->sendBuffer();
}

void SPI_OLED::pre_record_screen(int param)
{
    display->clearBuffer();
    if (param == 0)
    {
        display->drawStr(10, 25, "  Press the button to");
        display->drawStr(10, 35, "  record Temperature");
    }
    else if (param == 1)
    {
        display->drawStr(5, 25, "  Place and hold your");
        display->drawStr(10, 35, "  finger on sensor to");
        display->drawStr(10, 45, "    record pulse data");
    }
    else if (param == 2)
    {
        display->drawStr(0, 25,  "Place the Sthethoscope");
        display->drawStr(0, 35,  "and press the button to");
        display->drawStr(5, 45,  "    record heart beat");
    }
    else{
        display->drawStr(0, 25,  "Connect The BP addon");
        display->drawStr(0, 35,  "and press the button to");
        display->drawStr(0, 45,  "record blood pressure");
    }
    display->sendBuffer();
}

void SPI_OLED::record_screen(float progress)
{
    display->clearBuffer();
    display->setFont(u8g2_font_ncenB08_tr);
    char buff[20];
    sprintf(buff, "Heart Beat Audio");
    display->drawStr(15, 10, buff);
    display->setFont(u8g2_font_10x20_tf);
    sprintf(buff, "%0.2f%%", progress);
    display->drawStr(25, 35, buff);
    display->setFont(u8g2_font_ncenB08_tr);
    sprintf(buff, "Recording");
    display->drawStr(30, 60, buff);
    display->sendBuffer(); 
}

void SPI_OLED::record_screen(float pressure, bool inflating)
{
    display->clearBuffer();
    display->setFont(u8g2_font_ncenB08_tr);
    char buff[20];
    sprintf(buff, "Blood Pressure");
    display->drawStr(20, 10, buff);
    display->setFont(u8g2_font_10x20_tf);
    sprintf(buff, "%0.2f mmHg", pressure);
    display->drawStr(10, 35, buff);
    display->setFont(u8g2_font_ncenB08_tr);
    inflating?sprintf(buff, "Inflating"):sprintf(buff, "Deflating");
    display->drawStr(33, 60, buff);
    display->sendBuffer(); 
}

void SPI_OLED::record_screen(float ambient, float body)
{
    display->clearBuffer();
    display->setFont(u8g2_font_ncenB08_tr);
    display->drawStr(25, 10, "Temperature");
    char buff[20];
    display->setFont(u8g2_font_10x20_tf);
    sprintf(buff, "%0.2f F", body);
    display->drawStr(25, 35, buff);
    display->setFont(u8g2_font_ncenB08_tr);
    sprintf(buff, "Ambient");
    display->drawStr(10, 60, buff);
    sprintf(buff, ": %0.2f F", ambient);
    display->drawStr(70, 60, buff);
    display->sendBuffer();
}

void SPI_OLED::record_screen(uint16_t bpm, uint16_t n, uint8_t *wave, uint16_t num_samples)
{
    display->clearBuffer();
    display->setFont(u8g2_font_ncenB08_tr);
    char buff[30];
    sprintf(buff, "BPM : %3d         %3d/%3d", bpm, n, num_samples);
    display->drawStr(0, 10, buff);
    for (int i = 0; i < 63; i++)
        display->drawLine(i * 2, 63 - wave[i], (i + 1) * 2, 63 - wave[i + 1]);
    display->sendBuffer();
}

void SPI_OLED::result_screen(float systolic, float diastolic, float pulse)
{
    display->clearBuffer();
    display->setFont(u8g2_font_ncenB08_tr);
    display->drawStr(0, 10, "Blood Pressure Result");
    char buff[20];
    display->setFont(u8g2_font_9x18B_tf);
    sprintf(buff, "%d / %d mmHg", (int)round(systolic), (int)round(diastolic));
    display->drawStr(0, 35, buff);
    display->setFont(u8g2_font_ncenB08_tr);
    sprintf(buff, "Pulse rate");
    display->drawStr(00, 60, buff);
    sprintf(buff, ": %0.1f bpm", pulse);
    display->drawStr(60, 60, buff);
    display->sendBuffer();
}

void SPI_OLED::result_screen(float avgIBI, float avgBPM, float RMSSD, float SDNN, float avgSPO2)
{
    display->clear();
    display->setFont(u8g2_font_ncenB08_tr);
    char buff[22];
    char str[6];
    sprintf(buff, "HRV RESULT");
    display->drawStr(20, 8, buff);
    display->setFont(u8g2_font_5x8_tr);
    dtostrf(avgBPM, 4, 2, str);
    sprintf(buff, ": %s", str);
    display->drawStr(10, 23, "Avg BPM");
    display->drawStr(75, 23, buff);
    dtostrf(avgIBI, 4, 2, str);
    sprintf(buff, ": %s", str);
    display->drawStr(10, 33, "Avg IBI");
    display->drawStr(75, 33, buff);
    dtostrf(SDNN, 4, 2, str);
    sprintf(buff, ": %s", str);
    display->drawStr(10, 43, "SDNN");
    display->drawStr(75, 43, buff);
    dtostrf(RMSSD, 4, 2, str);
    sprintf(buff, ": %s", str);
    display->drawStr(10, 53, "RMSSD");
    display->drawStr(75, 53, buff);
    dtostrf(avgSPO2, 4, 2, str);
    sprintf(buff, ": %s", str);
    display->drawStr(10, 63, "Avg SPO2");
    display->drawStr(75, 63, buff);
    display->sendBuffer();
    delay(5000);
    display->setFont(u8g2_font_ncenB08_tr);
}

void SPI_OLED::finished_record_screen()
{
    display->clearBuffer();
    display->clearBuffer();
    display->drawBitmap(32, 0, 8, 40, file);
    display->drawStr(0, 51, " Recorded Succesfully ");
    display->sendBuffer();
}

void SPI_OLED::sent_screen(int param)
{
    display->clearBuffer();
    display->drawBitmap(32, 16, 8, 40, done);
    if(param==0)
    display->drawStr(5, 10, "Sent Temperature Data ");
    else if(param==1)
    display->drawStr(5, 10, " Sent Pulse Rate Data ");
    else if(param==2)
    display->drawStr(5, 10, " Sent Heart Beat Data ");
    else if(param==3)
    display->drawStr(20, 10, " Sent BP Data ");
    display->sendBuffer();
}