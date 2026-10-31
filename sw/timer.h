#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>

#define TIMER_BASE_ADDR   0x40008000UL

#define REG_TIMER_CTRL    (*(volatile uint32_t *)(TIMER_BASE_ADDR + 0x00))
#define REG_TIMER_RELOAD  (*(volatile uint32_t *)(TIMER_BASE_ADDR + 0x04))
#define REG_TIMER_VALUE   (*(volatile uint32_t *)(TIMER_BASE_ADDR + 0x08))
#define REG_TIMER_STATUS  (*(volatile uint32_t *)(TIMER_BASE_ADDR + 0x0C))

static inline void timer_init(uint32_t reload_ticks, uint8_t enable_irq) {
    REG_TIMER_RELOAD = reload_ticks;
    REG_TIMER_CTRL = 0x01 | (enable_irq ? 0x02 : 0x00);
}

static inline void timer_clear_tick(void) {
    REG_TIMER_STATUS = 0x01; // W1C
}

static inline uint8_t timer_poll_tick(void) {
    if (REG_TIMER_STATUS & 0x01) {
        REG_TIMER_STATUS = 0x01; // W1C
        return 1;
    }
    return 0;
}

#endif // TIMER_H
