class timer_sequencer extends uvm_sequencer #(timer_item);
`uvm_component_utils(timer_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
