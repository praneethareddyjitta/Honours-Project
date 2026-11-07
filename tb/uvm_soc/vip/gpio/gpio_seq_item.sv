/* =============================================================================
 * File        : gpio_seq_item.sv
 * Description : UVM Sequence Item for GPIO Transactions
 * ============================================================================= */

`ifndef GPIO_SEQ_ITEM_SV
`define GPIO_SEQ_ITEM_SV

class gpio_seq_item extends uvm_sequence_item;
    rand bit [7:0] gpio_in;
    bit [7:0]      gpio_out;
    bit            irq_gpio;
    realtime       timestamp;

    `uvm_object_utils_begin(gpio_seq_item)
        `uvm_field_int(gpio_in,   UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_out,  UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(irq_gpio,  UVM_ALL_ON | UVM_BIN)
        `uvm_field_real(timestamp, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "gpio_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("GPIO_TXN: IN=0x%02X OUT=0x%02X IRQ=%b @ %0t",
                         gpio_in, gpio_out, irq_gpio, timestamp);
    endfunction
endclass

`endif // GPIO_SEQ_ITEM_SV
