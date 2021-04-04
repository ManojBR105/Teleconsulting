#include "UTILS.h"

void UTILS::begin()
{
    if (!SPIFFS.begin(true))
    {
        Serial.println("SPIFFS Mount Failed");
        while (1)
            ;
    }
    else
    {
        Serial.println("SPIFFS Mounted");
    }
}

void UTILS::create_wavHeader(char *wavHeader, int headerSize, int wavSize)
{
    wavHeader[0] = 'R';
    wavHeader[1] = 'I';
    wavHeader[2] = 'F';
    wavHeader[3] = 'F';
    unsigned int fileSize = wavSize + headerSize - 8;
    wavHeader[4] = (byte)(fileSize & 0xFF);
    wavHeader[5] = (byte)((fileSize >> 8) & 0xFF);
    wavHeader[6] = (byte)((fileSize >> 16) & 0xFF);
    wavHeader[7] = (byte)((fileSize >> 24) & 0xFF);
    wavHeader[8] = 'W';
    wavHeader[9] = 'A';
    wavHeader[10] = 'V';
    wavHeader[11] = 'E';
    wavHeader[12] = 'f';
    wavHeader[13] = 'm';
    wavHeader[14] = 't';
    wavHeader[15] = ' ';
    wavHeader[16] = 0x10;
    wavHeader[17] = 0x00;
    wavHeader[18] = 0x00;
    wavHeader[19] = 0x00;
    wavHeader[20] = 0x01;
    wavHeader[21] = 0x00;
    wavHeader[22] = 0x01;
    wavHeader[23] = 0x00;
    wavHeader[24] = 0x80;
    wavHeader[25] = 0x3E;
    wavHeader[26] = 0x00;
    wavHeader[27] = 0x00;
    wavHeader[28] = 0x00;
    wavHeader[29] = 0x7D;
    wavHeader[30] = 0x01;
    wavHeader[31] = 0x00;
    wavHeader[32] = 0x02;
    wavHeader[33] = 0x00;
    wavHeader[34] = 0x10;
    wavHeader[35] = 0x00;
    wavHeader[36] = 'd';
    wavHeader[37] = 'a';
    wavHeader[38] = 't';
    wavHeader[39] = 'a';
    wavHeader[40] = (byte)(wavSize & 0xFF);
    wavHeader[41] = (byte)((wavSize >> 8) & 0xFF);
    wavHeader[42] = (byte)((wavSize >> 16) & 0xFF);
    wavHeader[43] = (byte)((wavSize >> 24) & 0xFF);
}

void UTILS::write_pulse_data(float avgIBI, float avgBPM, float RMSSD, float SDNN, float avgSPO2, uint16_t *BEAT_INT, uint16_t NUM_SAMPLES)
{
    File file = SPIFFS.open("/recording.txt", FILE_WRITE);

    file.println("------------HRV RESULTS------------");
    file.print("Avg IBI  :");
    file.println(avgIBI);
    file.print("Avg BPM  :");
    file.println(avgBPM);
    file.print("SDNN     :");
    file.println(SDNN);
    file.print("RMSSD    :");
    file.println(RMSSD);
    file.print("Avg SPO2 :");
    file.println(avgSPO2);
    file.println("------------IBI VALUES-------------");
    for (int i = 0; i < NUM_SAMPLES; i++)
        file.println(BEAT_INT[i]);

    file.close();
}

unsigned char* UTILS::get_pulse_data(size_t* readSize)
{
    File file = SPIFFS.open("/recording.txt");
    *readSize = file.size();
    unsigned char* readData = (unsigned char*)calloc(*readSize, sizeof(unsigned char));
    file.read(readData, *readSize);
    return readData;
}