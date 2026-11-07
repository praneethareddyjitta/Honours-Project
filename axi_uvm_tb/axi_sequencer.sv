class axi_sequencer extends uvm_sequencer #(axi_item);
`uvm_component_utils(axi_sequencer)
function new(string n,uvm_component p);super.new(n,p);endfunction
endclass
