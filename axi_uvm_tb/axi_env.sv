class axi_env extends uvm_env;
axi_agent agent; axi_scoreboard sb;
`uvm_component_utils(axi_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=axi_agent::type_id::create("agent",this); sb=axi_scoreboard::type_id::create("sb",this); endfunction
endclass
