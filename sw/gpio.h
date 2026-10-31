#ifndef GPIO_H
#define GPIO_H

#include <stdint.h>

#define GPIO_BASE_ADDR   0x4000A000UL

#define REG_GPIO_IN      (*(volatile uint32_t *)(GPIO_BASE_ADDR + 0x00))
#define REG_GPIO_OUT     (*(volatile uint32_t *)(GPIO_BASE_ADDR + 0x04))
#define REG_GPIO_DIR     (*(volatile uint32_t *)(GPIO_BASE_ADDR + 0x08))
#define REG_GPIO_INT_EN  (*(volatile uint32_t *)(GPIO_BASE_ADDR + 0x0C))

static inline void gpio_init(uint8_t output_mask) {
    REG_GPIO_DIR = (uint32_t)output_mask;
}

static inline void gpio_write(uint8_t value) {
    REG_GPIO_OUT = (uint32_t)value;
}

static inline uint8_t gpio_read(void) {
    return (uint8_t)(REG_GPIO_IN & 0xFF);
}

#endif // GPIO_H
