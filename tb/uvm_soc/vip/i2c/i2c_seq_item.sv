/* =============================================================================
 * File        : i2c_seq_item.sv
 * Description : UVM Sequence Item for I2C Transactions
 * ============================================================================= */

`ifndef I2C_SEQ_ITEM_SV
`define I2C_SEQ_ITEM_SV

class i2c_seq_item extends uvm_sequence_item;
    rand bit [6:0] addr;
    rand bit       rw;        // 0 = Write to slave, 1 = Read from slave
    rand bit [7:0] data_byte;
    bit            ack;       // 0 = ACK, 1 = NACK
    realtime       timestamp;

    `uvm_object_utils_begin(i2c_seq_item)
        `uvm_field_int(addr,      UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(rw,        UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(data_byte, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(ack,       UVM_ALL_ON | UVM_BIN)
        `uvm_field_real(timestamp, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "i2c_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("I2C_TXN: Addr=0x%02X RW=%s Data=0x%02X ACK=%b @ %0t",
                         addr, rw ? "RD" : "WR", data_byte, ack, timestamp);
    endfunction
endclass

`endif // I2C_SEQ_ITEM_SV
