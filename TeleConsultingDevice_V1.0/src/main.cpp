#include <I2S_MIC.h>
#include <TEMPERATURE_SENSOR.h>
#include <SPI_OLED.h>
#include <PULSE_OXIMETER.h>
#include <UTILS.h>
#include <BluetoothSerial.h>

extern "C"
{
#include "crypto/base64.h"
}

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

#define WS_PIN 25
#define SD_PIN 34
#define SCK_PIN 26
#define PORT 0
#define SAMPLE_RATE 16000
#define SAMPLE_BITS 16

#define RES 4
#define DC 2
#define CS 15

#define PUSH_BTN 14
#define TEMP_LED 19

enum deviceState
{
  NOT_CONNECTED,
  CONNECTED,
  RECORDING,
  DONE
};

enum Duration
{
  SHORT,
  LONG
};

char *dtostrf(double val, signed char width, unsigned char prec, char *s);

void bluetooth_init();
void btCallback(esp_spp_cb_event_t, esp_spp_cb_param_t);
void received_data_handler(String);

void record_for_duration(void);
void recordHeartBeat(int);
void recordPulseRate(int);
void recordTemperature(void);

void send_recording_start_signal(int);
void send_sent_signal(void);
void send_done_signal(void);

void wait_for_press(void);

void pulseOximeterCallback(void);

deviceState state = NOT_CONNECTED;
Duration duration;

volatile bool connected = false;
volatile bool record = false;
volatile bool done = false;
volatile bool finished = false;

I2S_MIC INMP441 = I2S_MIC(WS_PIN, SD_PIN, SCK_PIN, PORT, SAMPLE_RATE, SAMPLE_BITS);
TEMPERATURE_SENSOR MLX90614 = TEMPERATURE_SENSOR(TEMP_LED);
SPI_OLED SSD1306 = SPI_OLED(RES, DC, CS);
PULSE_OXIMETER MY_SENSOR = PULSE_OXIMETER(pulseOximeterCallback);
BluetoothSerial SerialBT;
UTILS Utils;

void setup()
{
  Serial.begin(9600);
  SSD1306.begin();
  INMP441.begin();
  delay(500);
  Utils.begin();
  delay(500);
  bluetooth_init();
  pinMode(PUSH_BTN, INPUT_PULLDOWN);
}

void loop()
{
  switch (state)
  {
  case NOT_CONNECTED:
    SSD1306.wait_screen();
    record = false;
    if (connected)
    {
      state = CONNECTED;
    }
    break;

  case CONNECTED:
    if (!connected)
      state = NOT_CONNECTED;
    else
    {
      SSD1306.selection_screen();
      if (record)
        state = RECORDING;
    }
    break;

  case RECORDING:
    if (!connected)
      state = NOT_CONNECTED;
    else if (!record)
      state = DONE;
    else
    {
      record_for_duration();
      record = false;
    }
    break;

  case DONE:
    if (!connected)
      state = NOT_CONNECTED;
    else
    {
      if (finished)
      {
        state = CONNECTED;
        delay(1000);
        send_done_signal();
      }
    }
    break;
  }
}

void record_for_duration()
{
  int time;

  send_recording_start_signal(0);
  SSD1306.pre_record_screen(0);
  delay(2000);
  recordTemperature();

  delay(2000);
  send_sent_signal();
  SSD1306.sent_screen(0);
  delay(3000);

  

  time = (duration == SHORT) ? 100 : 500;
  send_recording_start_signal(1);
  SSD1306.pre_record_screen(1);
  delay(2000);
  recordPulseRate(time);

  delay(2000);
  send_sent_signal();
  SSD1306.sent_screen(1);
  delay(3000);

  while(!done);
  done = false;

  time = (duration == SHORT) ? 30 : 120;
  send_recording_start_signal(2);
  SSD1306.pre_record_screen(2);
  wait_for_press();
  delay(2000);
  recordHeartBeat(time);

  delay(2000);
  send_sent_signal();
  SSD1306.sent_screen(2);
  delay(3000);

  while(!done);
  done = false;

  SSD1306.finished_record_screen();
  finished = true;
}

void recordHeartBeat(int secs)
{
  size_t bytesRead;
  float progress;
  uint32_t currRecordSize = 0;
  uint16_t i2sReadBuff[INMP441.getI2S_READ_SIZE()];
  uint32_t totRecordSize = secs * INMP441.getI2S_RECORD_SIZE_PER_SEC();

  String str = "file,wav,";
  int n = str.length() + 1;
  char buff[n];
  strncpy(buff, str.c_str(), n);
  SerialBT.write((uint8_t *)buff, str.length());
  Serial.flush();

  char wavHeader[44];
  Utils.create_wavHeader(wavHeader, sizeof(wavHeader), totRecordSize);
  SerialBT.write((uint8_t *)wavHeader, sizeof(wavHeader));
  Serial.flush();

  while (currRecordSize < totRecordSize)
  {
    INMP441.read(i2sReadBuff, &bytesRead);
    SerialBT.write((uint8_t *)i2sReadBuff, bytesRead);
    Serial.flush();
    progress = (float)currRecordSize * 100 / totRecordSize;
    SSD1306.record_screen(progress);
    currRecordSize += bytesRead;
  }
  SSD1306.record_screen(100.00);
}

void recordPulseRate(int numSamples)
{
  uint16_t bpm, n;
  MY_SENSOR.begin(numSamples);
  MY_SENSOR.update();
  uint32_t last = millis();
  uint8_t period = 25;
  while (!MY_SENSOR.is_done())
  {
    if ((millis() - last) >= period)
    {
      last = millis();
      MY_SENSOR.update();
      MY_SENSOR.get_record_data(&bpm, &n);
      MY_SENSOR.sensor_update();
      if (n)
        SSD1306.record_screen(bpm, n, MY_SENSOR.getWAVE(), MY_SENSOR.getNUM_SAMPLES());
      MY_SENSOR.sensor_update();
    }
  }
  float avg_ibi, avg_bpm, rmssd, sdnn, avg_spo2;
  MY_SENSOR.compute(&avg_ibi, &avg_bpm, &rmssd, &sdnn, &avg_spo2);
  SSD1306.result_screen(avg_ibi, avg_bpm, rmssd, sdnn, avg_spo2);
  Utils.write_pulse_data(avg_ibi, avg_bpm, rmssd, sdnn, avg_spo2, MY_SENSOR.getBEAT_INT(), MY_SENSOR.getNUM_SAMPLES());
  MY_SENSOR.reset();
  MY_SENSOR.close();

  String str = "file,txt,";
  int l = str.length() + 1;
  char buff[l];
  strncpy(buff, str.c_str(), l);
  SerialBT.write((uint8_t *)buff, str.length());
  Serial.flush();

  size_t readSize;
  size_t encodedSize;
  unsigned char *readData = Utils.get_pulse_data(&readSize);
  unsigned char *encodedData = base64_encode(readData, readSize, &encodedSize);
  SerialBT.write(encodedData, encodedSize);
  Serial.flush();

  free(readData);
  free(encodedData);
}

void recordTemperature()
{
  MLX90614.begin();
  wait_for_press();
  MLX90614.read();

  String str = "data,";
  int n = str.length() + 1;
  char buff[n];

  strncpy(buff, str.c_str(), n);
  SerialBT.write((uint8_t *)buff, str.length());
  Serial.flush();

  float amb_temp, obj_temp;
  MLX90614.get(&amb_temp, &obj_temp);
  char data[15];
  sprintf(data, "%.2f,%.2f", amb_temp, obj_temp);
  SerialBT.write((uint8_t *)data, 11);
}

void wait_for_press()
{
  while (true)
  {
    if (digitalRead(PUSH_BTN) == HIGH)
    {
      delay(500);
      break;
    }
  }
}

void pulseOximeterCallback()
{
  MY_SENSOR.on_beat_detected();
}

void btCallback(esp_spp_cb_event_t event, esp_spp_cb_param_t *param)
{
  String stringRead = "";
  if (event == ESP_SPP_SRV_OPEN_EVT)
  {
    Serial.println("Client Connected!");
    connected = true;
  }

  if (event == ESP_SPP_CLOSE_EVT)
  {
    Serial.println("Client Disconnected");
    connected = false;
    ESP.restart();
  }

  if (event == ESP_SPP_DATA_IND_EVT)
  {
    String receivedData = String((char *)param->data_ind.data).substring(0, param->data_ind.len);
    received_data_handler(receivedData);
  }
}

void received_data_handler(String message)
{
  Serial.println(message);
  if (message == "START,Short\n")
  {
    record = true;
    duration = SHORT;
  }
  else if (message == "START,Long\n")
  {
    record = true;
    duration = LONG;
  }
  else if (message == "SUCCESS\n")
  {
    done = true;
  }
}

void bluetooth_init()
{
  if (!SerialBT.begin("Tele Consulting Device"))
  {
    Serial.println("An error occurred initializing Bluetooth");
    ESP.restart();
  }
  else
  {
    Serial.println("Bluetooth initialized");
  }
  SerialBT.register_callback(btCallback);
  Serial.println("The device started, now you can pair it with bluetooth");
}

void send_recording_start_signal(int param)
{
  char buff[25];
  sprintf(buff, "RECORDING STARTED,%d\n", param);
  SerialBT.write((uint8_t *)buff, 20);
  SerialBT.flush();
}

void send_sent_signal()
{

  char buff[10];
  sprintf(buff, "SENT\n");
  SerialBT.write((uint8_t *)buff, 5);
  SerialBT.flush();
}

void send_done_signal()
{
  char buff[10];
  sprintf(buff, "DONE\n");
  SerialBT.write((uint8_t *)buff, 5);
  SerialBT.flush();
}
