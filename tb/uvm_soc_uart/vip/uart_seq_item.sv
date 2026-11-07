/* =============================================================================
 * File        : uart_seq_item.sv
 * Description : UVM Sequence Item representing an 8-N-1 UART character frame
 * ============================================================================= */

`ifndef UART_SEQ_ITEM_SV
`define UART_SEQ_ITEM_SV

class uart_seq_item extends uvm_sequence_item;

    typedef enum bit {
        DIRECTION_TX = 1'b0, // SoC transmitted byte
        DIRECTION_RX = 1'b1  // Host injected byte to SoC
    } dir_e;

    rand logic [7:0] data_byte;
    rand int         baud_div;
    rand dir_e       direction;
    logic            parity_err;
    logic            framing_err;
    time             timestamp;

    constraint c_baud {
        baud_div inside {16, 54, 868};
    }

    `uvm_object_utils_begin(uart_seq_item)
        `uvm_field_int (data_byte,   UVM_ALL_ON | UVM_HEX)
        `uvm_field_int (baud_div,    UVM_ALL_ON | UVM_DEC)
        `uvm_field_enum(dir_e, direction, UVM_ALL_ON)
        `uvm_field_int (parity_err,  UVM_ALL_ON)
        `uvm_field_int (framing_err, UVM_ALL_ON)
        `uvm_field_int (timestamp,   UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "uart_seq_item");
        super.new(name);
        data_byte   = 8'h00;
        baud_div    = 16;
        direction   = DIRECTION_TX;
        parity_err  = 1'b0;
        framing_err = 1'b0;
        timestamp   = 0;
    endfunction

    virtual function string convert2string();
        return $sformatf("UART_FRAME [Dir=%s Data=0x%02X ('%c') BaudDiv=%0d Err=(F:%0d,P:%0d) Time=%0t]",
                         direction.name(), data_byte, (data_byte >= 32 && data_byte <= 126) ? data_byte : 8'h2E,
                         baud_div, framing_err, parity_err, timestamp);
    endfunction

endclass

`endif // UART_SEQ_ITEM_SV
