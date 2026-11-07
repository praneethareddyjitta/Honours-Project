class pwm_monitor extends uvm_monitor;
virtual pwm_if vif;
uvm_analysis_port #(pwm_item) ap;
`uvm_component_utils(pwm_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
