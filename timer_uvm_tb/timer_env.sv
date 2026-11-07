class timer_env extends uvm_env;
timer_agent agent; timer_scoreboard sb;
`uvm_component_utils(timer_env)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); agent=timer_agent::type_id::create("agent",this); sb=timer_scoreboard::type_id::create("sb",this); endfunction
endclass
