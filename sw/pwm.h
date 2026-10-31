#ifndef PWM_H
#define PWM_H

#include <stdint.h>

#define PWM_BASE_ADDR    0x40002000UL

#define REG_PWM_DUTY     (*(volatile uint32_t *)(PWM_BASE_ADDR + 0x00))
#define REG_PWM_CTRL     (*(volatile uint32_t *)(PWM_BASE_ADDR + 0x04))
#define REG_PWM_STATUS   (*(volatile uint32_t *)(PWM_BASE_ADDR + 0x0C))

// Duty cycle range: 0 (0%) to 255 (100%)
static inline void pwm_set_duty(uint32_t duty) {
    REG_PWM_DUTY = duty;
}

static inline uint32_t pwm_get_duty(void) {
    return REG_PWM_DUTY;
}

#endif // PWM_H
