+incdir+../rtl/veer_el2/snapshots/default
+incdir+../rtl/veer_el2/design/include
+incdir+../rtl/veer_el2/design/lib
+incdir+../rtl
+incdir+../rtl/uart
+incdir+../rtl/i2c/verilog
+incdir+../tb
+incdir+../tb/i2c_tb/verilog
+incdir+../lib

-top tb_soc_closed_loop

# VeeR EL2 Core Complex
../rtl/veer_el2/snapshots/default/common_defines.vh
../rtl/veer_el2/design/include/el2_def.sv
-v ../rtl/veer_el2/design/lib/mem_lib.sv
-v ../rtl/veer_el2/design/lib/beh_lib.sv
../rtl/veer_el2/design/lib/el2_assert.sv
../rtl/veer_el2/design/el2_mubi_pkg.sv
../rtl/veer_el2/design/el2_lockstep_pkg.sv
../rtl/veer_el2/design/lib/el2_mem_if.sv
../rtl/veer_el2/design/lib/el2_prim_generic_buf.sv
../rtl/veer_el2/design/lib/el2_prim_buf.sv
../rtl/veer_el2/design/lib/el2_lib.sv
../rtl/veer_el2/design/lib/ahb_to_axi4.sv
../rtl/veer_el2/design/lib/axi4_to_ahb.sv

../rtl/veer_el2/design/dmi/dmi_mux.v
../rtl/veer_el2/design/dmi/dmi_wrapper.v
../rtl/veer_el2/design/dmi/dmi_jtag_to_core_sync.v
../rtl/veer_el2/design/dmi/rvjtag_tap.v

../rtl/veer_el2/design/dec/el2_dec_decode_ctl.sv
../rtl/veer_el2/design/dec/el2_dec_gpr_ctl.sv
../rtl/veer_el2/design/dec/el2_dec_ib_ctl.sv
../rtl/veer_el2/design/dec/el2_dec_pmp_ctl.sv
../rtl/veer_el2/design/dec/el2_dec_tlu_ctl.sv
../rtl/veer_el2/design/dec/el2_dec_trigger.sv
../rtl/veer_el2/design/dec/el2_dec.sv

../rtl/veer_el2/design/exu/el2_exu_alu_ctl.sv
../rtl/veer_el2/design/exu/el2_exu_mul_ctl.sv
../rtl/veer_el2/design/exu/el2_exu_div_ctl.sv
../rtl/veer_el2/design/exu/el2_exu.sv

../rtl/veer_el2/design/ifu/el2_ifu_aln_ctl.sv
../rtl/veer_el2/design/ifu/el2_ifu_compress_ctl.sv
../rtl/veer_el2/design/ifu/el2_ifu_ifc_ctl.sv
../rtl/veer_el2/design/ifu/el2_ifu_bp_ctl.sv
../rtl/veer_el2/design/ifu/el2_ifu_ic_mem.sv
../rtl/veer_el2/design/ifu/el2_ifu_mem_ctl.sv
../rtl/veer_el2/design/ifu/el2_ifu_iccm_mem.sv
../rtl/veer_el2/design/ifu/el2_ifu.sv

../rtl/veer_el2/design/lsu/el2_lsu_clkdomain.sv
../rtl/veer_el2/design/lsu/el2_lsu_addrcheck.sv
../rtl/veer_el2/design/lsu/el2_lsu_lsc_ctl.sv
../rtl/veer_el2/design/lsu/el2_lsu_stbuf.sv
../rtl/veer_el2/design/lsu/el2_lsu_bus_buffer.sv
../rtl/veer_el2/design/lsu/el2_lsu_bus_intf.sv
../rtl/veer_el2/design/lsu/el2_lsu_ecc.sv
../rtl/veer_el2/design/lsu/el2_lsu_dccm_mem.sv
../rtl/veer_el2/design/lsu/el2_lsu_dccm_ctl.sv
../rtl/veer_el2/design/lsu/el2_lsu_trigger.sv
../rtl/veer_el2/design/lsu/el2_lsu.sv

../rtl/veer_el2/design/dbg/el2_dbg.sv
../rtl/veer_el2/design/el2_pic_ctrl.sv
../rtl/veer_el2/design/el2_dma_ctrl.sv
../rtl/veer_el2/design/el2_pmp.sv
../rtl/veer_el2/design/el2_mem.sv
../rtl/veer_el2/design/el2_veer.sv
../rtl/veer_el2/design/el2_veer_lockstep.sv
../rtl/veer_el2/design/el2_veer_wrapper.sv
../rtl/veer_el2/design/veer_wrapper.sv

# AXI Infrastructure & Adapters
../rtl/interconnect/priority_encoder.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_5x20.v
../rtl/interconnect/axi4_to_axil_lite.sv
../rtl/interconnect/axi_adapter_64_to_32.sv

# Memories
../lib/axi_ram.sv

# Peripherals
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v
../rtl/uart/axi4_to_axi4lite_uart_adapter.v
../rtl/timer/timer.sv
../rtl/gpio/gpio.sv
../rtl/pwm/myip_v1_0_S00_AXI.v
../rtl/pwm/myip_v1_0.v
../rtl/i2c/verilog/i2c_master_bit_ctrl.v
../rtl/i2c/verilog/i2c_master_byte_ctrl.v
../rtl/i2c/axi_i2c_top.sv

# Interconnect Subsystem
../rtl/uart/axi_soc_top_5x20.v

# Top-level SoC Module
../rtl/soc_top.sv

# Verification Models & Testbench
../tb/i2c_tb/verilog/i2c_slave_model.v
../tb/tb_soc_closed_loop.sv
