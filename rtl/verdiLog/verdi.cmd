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
