class timer_test extends uvm_test;
timer_env env;
`uvm_component_utils(timer_test)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); env=timer_env::type_id::create("env",this); endfunction
endclass
