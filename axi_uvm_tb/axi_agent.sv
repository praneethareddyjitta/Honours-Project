class axi_agent extends uvm_agent;
axi_driver drv; axi_monitor mon; axi_sequencer seqr;
`uvm_component_utils(axi_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=axi_driver::type_id::create("drv",this); mon=axi_monitor::type_id::create("mon",this); seqr=axi_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
