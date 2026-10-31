#ifndef I2C_H
#define I2C_H

#include <stdint.h>

#define I2C_BASE_ADDR     0x40000000UL

#define REG_I2C_CTRL      (*(volatile uint32_t *)(I2C_BASE_ADDR + 0x00))
#define REG_I2C_PRESCALE  (*(volatile uint32_t *)(I2C_BASE_ADDR + 0x04))
#define REG_I2C_TXR       (*(volatile uint32_t *)(I2C_BASE_ADDR + 0x08))
#define REG_I2C_RXR       (*(volatile uint32_t *)(I2C_BASE_ADDR + 0x0C))
#define REG_I2C_CMD       (*(volatile uint32_t *)(I2C_BASE_ADDR + 0x10))
#define REG_I2C_STATUS    (*(volatile uint32_t *)(I2C_BASE_ADDR + 0x14))

#define I2C_CMD_START     (1 << 7)
#define I2C_CMD_STOP      (1 << 6)
#define I2C_CMD_READ      (1 << 5)
#define I2C_CMD_WRITE     (1 << 4)
#define I2C_CMD_ACK       (1 << 3)
#define I2C_CMD_IACK      (1 << 0)

#define I2C_STAT_RXACK    (1 << 7)
#define I2C_STAT_BUSY     (1 << 6)
#define I2C_STAT_AL       (1 << 5)
#define I2C_STAT_TIP      (1 << 1)
#define I2C_STAT_IF       (1 << 0)

static inline void i2c_init(uint16_t prescale) {
    REG_I2C_CTRL = 0x00; // Disable core
    REG_I2C_PRESCALE = prescale;
    REG_I2C_CTRL = 0x80; // Enable core
}

static inline void i2c_wait_tip(void) {
    while (REG_I2C_STATUS & I2C_STAT_TIP) {
        // Wait until Transfer In Progress clears
    }
}

static inline uint8_t i2c_write_byte(uint8_t slave_addr, uint8_t data) {
    // 1. Send Slave Address + Write (R/W = 0) with START
    REG_I2C_TXR = (slave_addr << 1) | 0;
    REG_I2C_CMD = I2C_CMD_START | I2C_CMD_WRITE;
    i2c_wait_tip();

    if (REG_I2C_STATUS & I2C_STAT_RXACK) {
        return 1; // NACK received
    }

    // 2. Send Data byte with STOP
    REG_I2C_TXR = data;
    REG_I2C_CMD = I2C_CMD_WRITE | I2C_CMD_STOP;
    i2c_wait_tip();

    return 0; // Success
}

static inline uint8_t i2c_read_byte(uint8_t slave_addr, uint8_t *data) {
    // 1. Send Slave Address + Read (R/W = 1) with START
    REG_I2C_TXR = (slave_addr << 1) | 1;
    REG_I2C_CMD = I2C_CMD_START | I2C_CMD_WRITE;
    i2c_wait_tip();

    if (REG_I2C_STATUS & I2C_STAT_RXACK) {
        return 1; // NACK received
    }

    // 2. Read byte with STOP and NACK (ACK=1 means don't ack next)
    REG_I2C_CMD = I2C_CMD_READ | I2C_CMD_STOP | I2C_CMD_ACK;
    i2c_wait_tip();

    *data = (uint8_t)(REG_I2C_RXR & 0xFF);
    return 0; // Success
}

#endif // I2C_H
