/* =============================================================================
 * File        : soc_uart_env.sv
 * Description : UVM Environment assembling UART VIP Agent, Scoreboard, and Coverage
 * ============================================================================= */

`ifndef SOC_UART_ENV_SV
`define SOC_UART_ENV_SV

class soc_uart_env extends uvm_env;
    `uvm_component_utils(soc_uart_env)

    uart_agent          agent;
    soc_uart_scoreboard sb;
    soc_uart_coverage   cov;

    function new(string name = "soc_uart_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = uart_agent::type_id::create("agent", this);
        sb    = soc_uart_scoreboard::type_id::create("sb", this);
        cov   = soc_uart_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect Monitor analysis port to Scoreboard & Coverage collector
        agent.ap.connect(sb.tx_imp);
        agent.ap.connect(cov.analysis_export);
    endfunction

endclass

`endif // SOC_UART_ENV_SV
