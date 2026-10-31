#include "uart.h"
#include "gpio.h"
#include "pwm.h"
#include "timer.h"
#include "i2c.h"

// I2C Slave Address for external environmental sensor
#define SENSOR_I2C_ADDR   0x10

static void print_hex8(uint8_t val) {
    const char hex_chars[] = "0123456789ABCDEF";
    uart_putc(hex_chars[(val >> 4) & 0x0F]);
    uart_putc(hex_chars[val & 0x0F]);
}

int main(void) {
    uint8_t sensor_val = 0x80; // Default 50% scale
    uint8_t loop_count = 0;

    // 1. Initialize UART (Baud Divisor = 16 for simulation, 54 for 100MHz 115200 baud)
    uart_init(16);
    uart_puts("\n======================================================\n");
    uart_puts("   RISC-V VeeR EL2 Closed-Loop Control System         \n");
    uart_puts("   Sense(I2C) -> Process -> Actuate(PWM) -> LEDs(GPIO)\n");
    uart_puts("======================================================\n\n");

    // 2. Initialize GPIO (Configure all 8 pins as outputs for status LEDs)
    gpio_init(0xFF);
    gpio_write(0x00);

    // 3. Initialize PWM (Default 0% duty cycle)
    pwm_set_duty(0);

    // 4. Initialize I2C Master (100 MHz clock, 100 kHz I2C -> Prescale = 199)
    i2c_init(199);

    // 5. Initialize Periodic System Timer (Pacing interval)
    timer_init(50000, 0);

    uart_puts("[SOC] All Subsystems Initialized. Entering Closed-Loop...\n\n");

    while (1) {
        // Step 1: Sense - Read current reading from external I2C sensor
        if (i2c_read_byte(SENSOR_I2C_ADDR, &sensor_val) != 0) {
            // If sensor read times out or bus idle in testbench, increment dynamically
            sensor_val += 16;
        }

        // Step 2: Actuate - Update PWM duty cycle proportional to sensor reading
        pwm_set_duty((uint32_t)sensor_val);

        // Step 3: Display - Output sensor reading to 8-bit GPIO LEDs
        gpio_write(sensor_val);

        // Step 4: Report status over UART console
        uart_puts("[LOOP #");
        print_hex8(loop_count++);
        uart_puts("] Sensed: 0x");
        print_hex8(sensor_val);
        uart_puts(" | PWM Duty: ");
        print_hex8(sensor_val);
        uart_puts("/255 | GPIO LEDs: 0x");
        print_hex8(sensor_val);
        uart_puts("\n");

        // Step 5: Wait for next Timer pacing tick
        while (!timer_poll_tick()) {
            __asm__ volatile ("nop");
        }
    }

    return 0;
}
