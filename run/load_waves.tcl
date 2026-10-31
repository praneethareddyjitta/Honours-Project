wvCreateWindow
wvAddSignal -win $_nWave2 /tb_soc_baseline_c/clk
wvAddSignal -win $_nWave2 /tb_soc_baseline_c/rst_n
wvAddSignal -win $_nWave2 -group "Processor Core (VeeR EL2)" /tb_soc_baseline_c/dut/u_veer_core/trace_rv_i_valid_ip
wvAddSignal -win $_nWave2 -group "Processor Core (VeeR EL2)" /tb_soc_baseline_c/dut/u_veer_core/trace_rv_i_address_ip[31:0]
wvAddSignal -win $_nWave2 -group "Processor Core (VeeR EL2)" /tb_soc_baseline_c/dut/u_veer_core/trace_rv_i_insn_ip[31:0]
wvAddSignal -win $_nWave2 -group "Instruction Bus (IFU)" /tb_soc_baseline_c/dut/ifu_axi_araddr[31:0]
wvAddSignal -win $_nWave2 -group "Instruction Bus (IFU)" /tb_soc_baseline_c/dut/ifu_axi_rdata[63:0]
wvAddSignal -win $_nWave2 -group "Data Bus to Peripherals (LSU)" /tb_soc_baseline_c/dut/lsu_axi_awvalid
wvAddSignal -win $_nWave2 -group "Data Bus to Peripherals (LSU)" /tb_soc_baseline_c/dut/lsu_axi_awaddr[31:0]
wvAddSignal -win $_nWave2 -group "Output Verification" /tb_soc_baseline_c/dut/uart_tx
wvAddSignal -win $_nWave2 -group "Output Verification" /tb_soc_baseline_c/dut/gpio_out[7:0]
wvAddSignal -win $_nWave2 -group "Output Verification" /tb_soc_baseline_c/dut/pwm_out
wvZoomAll -win $_nWave2
