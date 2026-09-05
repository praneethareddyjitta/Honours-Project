wvCreateWindow
wvOpenFile -win $_nWave2 \
           {/home/student/Documents/1602-23-735-163/IPs/aes_core-master/sim/rtl_sim/bin/dump.fsdb}
verdiWindowResize -win $_Verdi_1 "340" "92" "900" "700"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiSetActWin -win $_nWave2
debExit
