+incdir+../rtl
+incdir+../rtl/uart
+incdir+../rtl/i2c/verilog
+incdir+../tb
+incdir+../lib

# Interconnect Crossbar (5x20)
../rtl/interconnect/priority_encoder.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_5x20.v

# UART Subsystem (M05 @ 0x4000_6000)
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v
../rtl/uart/axi4_to_axi4lite_uart_adapter.v

# Protocol Bridges
../rtl/interconnect/axi4_to_axil_lite.sv
../rtl/i2c/axi_to_wb_bridge.v

# Integrated Peripheral IPs:
# Timer (M06 @ 0x4000_8000)
../rtl/timer/timer.sv

# GPIO (M07 @ 0x4000_A000)
../rtl/gpio/gpio.sv

# PWM (M03 @ 0x4000_2000)
../rtl/pwm/pwm.sv

# I2C (M02 @ 0x4000_0000)
../rtl/i2c/verilog/i2c_master_bit_ctrl.v
../rtl/i2c/verilog/i2c_master_byte_ctrl.v
../rtl/i2c/verilog/i2c_master_top.v

# Top-Level SoC Integration
../rtl/uart/axi_soc_top_5x20.v

# Top-Level Verification Testbench
../tb/tb_axi_soc_top_5x20_all_ips.sv
