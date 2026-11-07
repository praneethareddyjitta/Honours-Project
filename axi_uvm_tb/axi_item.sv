class axi_item extends uvm_sequence_item;

  rand bit [31:0] awaddr;
  rand bit [2:0] awprot;
  rand bit awvalid;
  bit awready;
  rand bit [31:0] wdata;
  rand bit [3:0] wstrb;
  rand bit wvalid;
  bit wready;
  bit [1:0] bresp;
  bit bvalid;
  rand bit bready;
  rand bit [31:0] araddr;
  rand bit [2:0] arprot;
  rand bit arvalid;
  bit arready;
  bit [31:0] rdata;
  bit [1:0] rresp;
  bit rvalid;
  rand bit rready;

  `uvm_object_utils(axi_item)

  function new(string name="axi_item"); super.new(name); endfunction
endclass
