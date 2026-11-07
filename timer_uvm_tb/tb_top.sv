module tb_top;
import uvm_pkg::*; import timer_pkg::*;
timer_if vif();
initial run_test("timer_test");
endmodule
