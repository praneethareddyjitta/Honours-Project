// -----------------------------------------------------------------------------
// axi_bfm.vh : tiny AXI4 master BFM (tasks) shared by both testbenches.
// The including testbench must declare:
//   reg clk; integer errors;
//   reg  s_axi_aw*/w*/bready/ar*/rready  (master-driven)
//   wire s_axi_awready/wready/b*/arready/r* (slave-driven)
// -----------------------------------------------------------------------------
task check(input cond, input [8*72-1:0] msg);
    begin
        if (!cond) begin
            errors = errors + 1;
            $display("[%0t] CHECK FAILED: %0s", $time, msg);
        end
    end
endtask

// One AXI4 write: len+1 W beats, independent AW/W/B timing.
//   aw_dly / w_dly : cycles before AWVALID / first WVALID is raised
//   b_dly          : cycles BREADY is held low AFTER BVALID is seen
task axi_write(input [7:0] id, input [31:0] addr, input [7:0] len, input [2:0] size,
               input [31:0] data0, input [3:0] strb,
               input integer aw_dly, input integer w_dly, input integer b_dly,
               output [1:0] resp, output [7:0] bid_o);
    integer i;
    begin
        fork
            begin : aw_proc
                repeat (aw_dly) @(posedge clk);
                s_axi_awid <= id;   s_axi_awaddr <= addr; s_axi_awlen <= len;
                s_axi_awsize <= size; s_axi_awburst <= 2'b01;
                s_axi_awvalid <= 1'b1;
                @(posedge clk);
                while (!s_axi_awready) @(posedge clk);
                s_axi_awvalid <= 1'b0;
            end
            begin : w_proc
                repeat (w_dly) @(posedge clk);
                for (i = 0; i <= len; i = i + 1) begin
                    s_axi_wdata <= data0 + i; s_axi_wstrb <= strb;
                    s_axi_wlast <= (i == len);
                    s_axi_wvalid <= 1'b1;
                    @(posedge clk);
                    while (!s_axi_wready) @(posedge clk);
                end
                s_axi_wvalid <= 1'b0;
                s_axi_wlast  <= 1'b0;
            end
            begin : b_proc
                @(posedge clk);
                while (!s_axi_bvalid) @(posedge clk);
                repeat (b_dly) @(posedge clk);
                s_axi_bready <= 1'b1;
                @(posedge clk);
                check(s_axi_bvalid, "B not held until BREADY (bvalid dropped)");
                resp  = s_axi_bresp;
                bid_o = s_axi_bid;
                s_axi_bready <= 1'b0;
            end
        join
    end
endtask

// One AXI4 read: collects len+1 beats, checks RLAST placement and RID.
task axi_read(input [7:0] id, input [31:0] addr, input [7:0] len, input [2:0] size,
              input integer ar_dly, input integer r_dly,
              output [1:0] resp, output [31:0] data, output integer nbeats);
    reg done;
    begin
        nbeats = 0; done = 0; resp = 0; data = 0;
        fork
            begin : ar_proc
                repeat (ar_dly) @(posedge clk);
                s_axi_arid <= id; s_axi_araddr <= addr; s_axi_arlen <= len;
                s_axi_arsize <= size; s_axi_arburst <= 2'b01;
                s_axi_arvalid <= 1'b1;
                @(posedge clk);
                while (!s_axi_arready) @(posedge clk);
                s_axi_arvalid <= 1'b0;
            end
            begin : r_proc
                while (!done) begin
                    @(posedge clk);
                    while (!s_axi_rvalid) @(posedge clk);
                    repeat (r_dly) @(posedge clk);
                    s_axi_rready <= 1'b1;
                    @(posedge clk);
                    check(s_axi_rvalid, "R not held until RREADY (rvalid dropped)");
                    check(s_axi_rid == id, "RID mismatch");
                    if (nbeats == 0) begin resp = s_axi_rresp; data = s_axi_rdata; end
                    nbeats = nbeats + 1;
                    if (s_axi_rlast) begin
                        check(nbeats == len + 1, "RLAST at wrong beat");
                        done = 1;
                    end else if (nbeats > len) begin
                        check(1'b0, "missing RLAST on final beat");
                        done = 1;
                    end
                    s_axi_rready <= 1'b0;
                end
            end
        join
    end
endtask
