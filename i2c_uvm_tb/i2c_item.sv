class i2c_item extends uvm_sequence_item;

  rand bit [31:0] s_axi_awaddr;
  rand bit s_axi_awvalid;
  bit s_axi_awready;
  rand bit [31:0] s_axi_wdata;
  rand bit [3:0] s_axi_wstrb;
  rand bit s_axi_wvalid;
  bit s_axi_wready;
  bit [1:0] s_axi_bresp;
  bit s_axi_bvalid;
  rand bit s_axi_bready;
  rand bit [31:0] s_axi_araddr;
  rand bit s_axi_arvalid;
  bit s_axi_arready;
  bit [31:0] s_axi_rdata;
  bit [1:0] s_axi_rresp;
  bit s_axi_rvalid;
  rand bit s_axi_rready;
  bit scl;
  bit sda;
  bit irq_i2c;

  `uvm_object_utils(i2c_item)

  function new(string name="i2c_item"); super.new(name); endfunction
endclass
