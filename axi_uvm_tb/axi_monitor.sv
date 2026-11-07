class axi_monitor extends uvm_monitor;
virtual axi_if vif;
uvm_analysis_port #(axi_item) ap;
`uvm_component_utils(axi_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
