AXI4-Lite AES-128 integration package

IMPORTANT:
- Existing AES RTL is not modified.
- The wrapper is AXI4-Lite, not full AXI4.
- The wrapper rejects bursts with SLVERR; this is intentional for a register interface.
- Existing AES reset is active-low (rst=0).

Files:
  rtl/axi_aes_slave.v
  rtl/axi_aes_top.v
  tb/axi_aes_tb.v
  filelist.f
  filelist_portable.f

From a directory where filelist.f is visible:
  vcs -full64 -sverilog -debug_access+all -f filelist.f -top axi_aes_tb -o simv
  ./simv

For FSDB:
  vcs -full64 -sverilog -debug_access+all -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a -DFSDB -f filelist.f -top axi_aes_tb -o simv
  ./simv
  verdi -ssf aes_axi.fsdb &

If your lab's VERDI_HOME path differs, use the PLI path configured by your VCS/Verdi installation.
