class timer_agent extends uvm_agent;
timer_driver drv; timer_monitor mon; timer_sequencer seqr;
`uvm_component_utils(timer_agent)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); drv=timer_driver::type_id::create("drv",this); mon=timer_monitor::type_id::create("mon",this); seqr=timer_sequencer::type_id::create("seqr",this); endfunction
function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
endclass
