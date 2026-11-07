/* =============================================================================
 * File        : soc_uart_coverage.sv
 * Description : UVM Functional Coverage collector for UART transmission verification
 * ============================================================================= */

`ifndef SOC_UART_COVERAGE_SV
`define SOC_UART_COVERAGE_SV

class soc_uart_coverage extends uvm_subscriber #(uart_seq_item);
    `uvm_component_utils(soc_uart_coverage)

    uart_seq_item cur_item;

    covergroup cg_uart_transmission;
        cp_char: coverpoint cur_item.data_byte {
            bins printable_ascii = {[8'h20 : 8'h7E]};
            bins newline_cr     = {8'h0A, 8'h0D};
            bins null_char      = {8'h00};
        }
        cp_baud: coverpoint cur_item.baud_div {
            bins sim_baud  = {16};
            bins real_baud = {54, 868};
        }
        cp_frame_err: coverpoint cur_item.framing_err {
            bins no_error = {1'b0};
            bins error    = {1'b1};
        }
    endgroup

    function new(string name = "soc_uart_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_uart_transmission = new();
    endfunction

    virtual function void write(uart_seq_item t);
        cur_item = t;
        cg_uart_transmission.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COVERAGE", $sformatf("UART Functional Coverage: %0.2f%%", cg_uart_transmission.get_coverage()), UVM_LOW)
    endfunction

endclass

`endif // SOC_UART_COVERAGE_SV
