#include "I2S_MIC.h"

I2S_MIC::I2S_MIC(int ws, int sd, int sck, int port, int sample_rate, int sample_bits)
{
    I2S_WS = ws;
    I2S_SD = sd;
    I2S_SCK = sck;
    I2S_PORT = port;
    I2S_SAMPLE_RATE = sample_rate;
    I2S_SAMPLE_BITS = sample_bits;
    I2S_RECORD_SIZE_PER_SEC = sample_rate * sample_bits / 8;
}

void I2S_MIC::begin()
{
    static const i2s_config_t i2s_config = {
        .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
        .sample_rate = I2S_SAMPLE_RATE,
        .bits_per_sample = i2s_bits_per_sample_t(I2S_SAMPLE_BITS),
        .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
        .communication_format = (i2s_comm_format_t)(I2S_COMM_FORMAT_I2S | I2S_COMM_FORMAT_I2S_MSB),
        .intr_alloc_flags = 0,
        .dma_buf_count = 8,
        .dma_buf_len = 64,
        .use_apll = false};

    static const i2s_pin_config_t pin_config = {
        .bck_io_num = I2S_SCK,
        .ws_io_num = I2S_WS,
        .data_out_num = I2S_PIN_NO_CHANGE,
        .data_in_num = I2S_SD};

    i2s_driver_install((i2s_port_t)I2S_PORT, &i2s_config, 0, NULL);
    i2s_set_pin((i2s_port_t)I2S_PORT, &pin_config);
    i2s_start((i2s_port_t)I2S_PORT);
}

void I2S_MIC::read(uint16_t *dest_addr, size_t *bytes_read)
{
    size_t i2s_dest_len = I2S_READ_SIZE * sizeof(uint16_t);
    i2s_read((i2s_port_t)I2S_PORT, dest_addr, i2s_dest_len, bytes_read, portMAX_DELAY);
}

int I2S_MIC::getI2S_RECORD_SIZE_PER_SEC(){
    return I2S_RECORD_SIZE_PER_SEC;
}

int I2S_MIC::getI2S_READ_SIZE() {
        return I2S_READ_SIZE;
}
