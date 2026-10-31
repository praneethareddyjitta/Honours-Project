+incdir+../rtl
+incdir+../rtl/uart
+incdir+../tb
+incdir+../lib

# Interconnect
../rtl/interconnect/priority_encoder.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_5x20.v

# UART Subsystem
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v
../rtl/uart/axi4_to_axi4lite_uart_adapter.v

# Protocol Bridge
../rtl/interconnect/axi4_to_axil_lite.sv

# Integrated IPs: Timer & GPIO
../rtl/timer/timer.sv
../rtl/gpio/gpio.sv

# Top SoC
../rtl/uart/axi_soc_top_5x20.v

# Verification Testbench
../tb/tb_axi_soc_top_5x20_timer_gpio.sv
