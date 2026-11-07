module tb_top;
import uvm_pkg::*; import axi_pkg::*;
axi_if vif();
initial run_test("axi_test");
endmodule
