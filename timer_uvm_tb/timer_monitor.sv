class timer_monitor extends uvm_monitor;
virtual timer_if vif;
uvm_analysis_port #(timer_item) ap;
`uvm_component_utils(timer_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
