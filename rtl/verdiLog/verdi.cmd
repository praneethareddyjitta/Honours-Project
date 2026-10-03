verdiSetActWin -dock widgetDock_<Message>
simSetSimulator "-vcssv" -exec \
           "/home/student/Documents/1602-23-735-163/proj-dir/rtl/simv" -args
debImport "-dbdir" \
          "/home/student/Documents/1602-23-735-163/proj-dir/rtl/simv.daidir"
debLoadSimResult /home/student/Documents/1602-23-735-163/proj-dir/rtl/dump.fsdb
wvCreateWindow
verdiWindowResize -win $_Verdi_1 -10 "19" "900" "700"
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetSignalFilter -win $_nWave2 "uart_tx_i"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter"
wvGetSignalSetSignalFilter -win $_nWave2 "uart_tx_i"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter/uart"
wvGetSignalSetScope -win $_nWave2 \
           "/tb_axi4_to_axi4lite_uart_adapter/uart/uart_controller_inst/uart_transmitter_inst"
wvGetSignalSetScope -win $_nWave2 \
           "/tb_axi4_to_axi4lite_uart_adapter/uart/axi_internal_fifo_tx_inst"
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter/uart"
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awaddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awvalid_i} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 1 2 3 )} 
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awaddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wdata_i\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wvalid_i} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 4 5 6 )} 
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awaddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wdata_i\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_rx_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_tx_o} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 7 8 )} 
wvSetPosition -win $_nWave2 {("G1" 8)}
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter"
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter/dut"
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter/uart"
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awaddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wdata_i\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_rx_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_tx_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_araddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arvalid_i} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 9 10 11 )} 
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 14)}
wvSetPosition -win $_nWave2 {("G1" 14)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awaddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wdata_i\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_rx_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_tx_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_araddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rdata\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rready_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 12 13 14 )} 
wvSetPosition -win $_nWave2 {("G1" 14)}
verdiDockWidgetMaximize -dock windowDock_nWave_2
wvSelectSignal -win $_nWave2 {( "G1" 8 )} 
wvSelectSignal -win $_nWave2 {( "G1" 7 )} 
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSelectSignal -win $_nWave2 {( "G1" 3 )} 
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvSelectSignal -win $_nWave2 {( "G1" 12 )} 
wvGetSignalOpen -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awaddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wdata_i\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_rx_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_tx_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_araddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rdata\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rready_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rvalid} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_aclk_i} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 15 )} 
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awaddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wdata_i\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_rx_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_tx_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_araddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rdata\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rready_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rvalid} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_aclk_i} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 15 )} 
wvSetPosition -win $_nWave2 {("G1" 15)}
wvGetSignalClose -win $_nWave2
wvSetCursor -win $_nWave2 4166668.837306 -snap {("G1" 4)}
wvSetCursor -win $_nWave2 3454149.209560 -snap {("G1" 4)}
wvSelectSignal -win $_nWave2 {( "G1" 8 )} 
wvZoom -win $_nWave2 3525298.392988 3696127.830533
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvSetCursor -win $_nWave2 1369268.303249 -snap {("G1" 4)}
wvSetCursor -win $_nWave2 1369268.303249 -snap {("G1" 4)}
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvSetCursor -win $_nWave2 1221903.104693 -snap {("G1" 4)}
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvSetCursor -win $_nWave2 55261.949458 -snap {("G1" 4)}
wvSetCursor -win $_nWave2 4024911.985560 -snap {("G1" 12)}
wvSetCursor -win $_nWave2 4077103.826715 -snap {("G1" 12)}
wvSetCursor -win $_nWave2 4077103.826715 -snap {("G1" 12)}
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomIn -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvSetCursor -win $_nWave2 3631938.122744 -snap {("G2" 0)}
wvZoomIn -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomOut -win $_nWave2
wvSetCursor -win $_nWave2 1461471.428571 -snap {("G2" 0)}
verdiDockWidgetHide -dock windowDock_nWave_2
verdiSetActWin -win $_OneSearch
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcSelect -win $_nTrace1 -range {71 71 1 15 1 1}
srcTBAddBrkPnt -win $_nTrace1 -line 71 -file \
           /home/student/Documents/1602-23-735-163/proj-dir/tb/tb_axi4_to_axi4lite_uart_adapter.v
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcSelect -win $_nTrace1 -range {71 73 1 1 1 1}
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -range {101 102 1 1 2 1}
srcHBSelect "tb_axi_soc_top_smoke" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_axi_soc_top_smoke" -win $_nTrace1
srcSetScope "tb_axi_soc_top_smoke" -delim "." -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke" -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_axi_uart" -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_axi_uart" -win $_nTrace1
srcSetScope "tb_axi_soc_top_smoke.u_top.u_axi_uart" -delim "." -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_axi_uart" -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_interconnect" -win $_nTrace1
srcSetScope "tb_axi_soc_top_smoke.u_top.u_interconnect" -delim "." -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_interconnect" -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_uart_adapter" -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_uart_adapter" -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_uart_adapter" -win $_nTrace1
srcSetScope "tb_axi_soc_top_smoke.u_top.u_uart_adapter" -delim "." -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_uart_adapter" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "w_strb_err" -line 291 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave2
verdiSetActWin -win $_nWave2
verdiDockWidgetSetCurTab -dock windowDock_nWave_2
verdiDockWidgetMaximize -dock windowDock_nWave_2
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetCursor -win $_nWave2 159678.719397 -snap {("G1" 6)}
wvSelectSignal -win $_nWave2 {( "G1" 5 )} 
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter"
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter/uart"
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awaddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wdata_i\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_rx_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_tx_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_araddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rdata\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rready_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rvalid} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_aclk_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wrresp} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 16 )} 
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awaddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_awvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wdata_i\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_rx_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/uart_tx_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_araddr_i\[4:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arready_o} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_arvalid_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rdata\[31:0\]} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rready_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_rvalid} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_aclk_i} \
{/tb_axi4_to_axi4lite_uart_adapter/uart/axi_wrresp} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 16 )} 
wvSetPosition -win $_nWave2 {("G1" 16)}
wvGetSignalClose -win $_nWave2
wvSelectGroup -win $_nWave2 {G2}
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter"
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter/uart"
wvGetSignalSetScope -win $_nWave2 \
           "/tb_axi4_to_axi4lite_uart_adapter/uart/axi_internal_fifo_rx_inst"
wvGetSignalSetScope -win $_nWave2 \
           "/tb_axi4_to_axi4lite_uart_adapter/uart/axi_internal_fifo_tx_inst"
wvGetSignalSetScope -win $_nWave2 \
           "/tb_axi4_to_axi4lite_uart_adapter/uart/uart_controller_inst"
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter/uart"
wvSelectSignal -win $_nWave2 {( "G1" 16 )} 
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 14)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSetPosition -win $_nWave2 {("G1" 12)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSetPosition -win $_nWave2 {("G1" 14)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G1" 12)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvGetSignalSetScope -win $_nWave2 "/tb_axi4_to_axi4lite_uart_adapter/uart"
wvSetPosition -win $_nWave2 {("G1" 16)}
verdiDockWidgetHide -dock windowDock_nWave_2
verdiSetActWin -win $_OneSearch
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_uart_adapter" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_axi_uart" -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_axi_uart" -win $_nTrace1
srcSetScope "tb_axi_soc_top_smoke.u_top.u_axi_uart" -delim "." -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_axi_uart" -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top" -win $_nTrace1
srcSetScope "tb_axi_soc_top_smoke.u_top" -delim "." -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top" -win $_nTrace1
uniFindSearchString -widget <Inst._Tree> -pattern "uart" -next
uniFindSearchString -widget <Inst._Tree> -pattern "uart" -next
uniFindSearchString -widget <Inst._Tree> -pattern "uart" -next
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_axi_uart" -win $_nTrace1
srcSetScope "tb_axi_soc_top_smoke.u_top.u_axi_uart" -delim "." -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_axi_uart" -win $_nTrace1
srcDeselectAll -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
uniFindSearchString -widget MTB_SOURCE_TAB_1 -pattern "wrresp" -next
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -range {120 122 1 1 1 1} -backward
srcDeselectAll -win $_nTrace1
srcSelect -signal "axi_nrdresp" -line 124 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -range {117 122 1 8 1 1} -backward
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -range {86 105 1 1 1 1} -backward
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "axi_awaddr_i" -line 92 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -range {80 96 14 1 1 1}
wvCreateWindow
wvSetPosition -win $_nWave3 {("G1" 0)}
wvOpenFile -win $_nWave3 \
           {/home/student/Documents/1602-23-735-163/proj-dir/rtl/dump.fsdb}
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave3
verdiSetActWin -win $_nWave3
wvSetCursor -win $_nWave3 122825.031938 -snap {("G1" 10)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "axi_rdata_o" -line 86 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -range {91 105 14 1 1 1}
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave3
verdiDockWidgetMaximize -dock windowDock_nWave_3
verdiSetActWin -win $_nWave3
wvZoomAll -win $_nWave3
wvSetCursor -win $_nWave3 229353.867991 -snap {("G1" 15)}
wvSetCursor -win $_nWave3 694097.232079 -snap {("G1" 14)}
wvSetCursor -win $_nWave3 1622717.875355 -snap {("G1" 2)}
wvSelectGroup -win $_nWave3 {G1}
wvSetCursor -win $_nWave3 2846555.379114 -snap {("G1" 6)}
wvSetCursor -win $_nWave3 3070170.132888 -snap {("G1" 5)}
wvZoom -win $_nWave3 3085279.237872 3215217.540741
wvZoomAll -win $_nWave3
wvGetSignalOpen -win $_nWave3
wvGetSignalSetScope -win $_nWave3 "/_vcs_msglog"
wvGetSignalSetScope -win $_nWave3 "/tb_axi4_to_axi4lite_uart_adapter"
wvGetSignalSetScope -win $_nWave3 "/tb_axi4_to_axi4lite_uart_adapter/dut"
wvGetSignalSetScope -win $_nWave3 "/tb_axi4_to_axi4lite_uart_adapter/uart"
wvGetSignalSetScope -win $_nWave3 "/tb_axi4_to_axi4lite_uart_adapter"
wvGetSignalSetScope -win $_nWave3 "/tb_axi_soc_top_smoke/u_top/u_interconnect"
wvGetSignalClose -win $_nWave3
verdiDockWidgetHide -dock windowDock_nWave_3
verdiSetActWin -win $_OneSearch
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcDeselectAll -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_axi_soc_top_smoke.u_top" -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_interconnect" -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_interconnect" -win $_nTrace1
srcSetScope "tb_axi_soc_top_smoke.u_top.u_interconnect" -delim "." -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top.u_interconnect" -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcHBSelect "tb_axi_soc_top_smoke.u_top" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_axi_soc_top_smoke.u_top" -win $_nTrace1
srcSetScope "tb_axi_soc_top_smoke.u_top" -delim "." -win $_nTrace1
srcHBSelect "tb_axi_soc_top_smoke.u_top" -win $_nTrace1
srcDeselectAll -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcDeselectAll -win $_nTrace1
srcSelect -signal "u03_wstrb" -line 698 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -win $_nTrace1 -range {683 685 1 12 22 1}
srcDeselectAll -win $_nTrace1
srcSelect -signal "u03_awaddr" -line 685 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave3
verdiSetActWin -win $_nWave3
srcDeselectAll -win $_nTrace1
srcSelect -signal "u03_awvalid" -line 695 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave3
srcDeselectAll -win $_nTrace1
srcSelect -signal "u03_awready" -line 696 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave3
srcDeselectAll -win $_nTrace1
srcSelect -signal "u03_wdata" -line 697 -pos 1 -win $_nTrace1
srcAddSelectedToWave -clipboard -win $_nTrace1
wvDrop -win $_nWave3
debExit
