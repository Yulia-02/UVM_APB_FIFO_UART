`timescale 1ns/1ps

module tb_top;
    // import UVM package
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import apb_uart_pkg::*;
    // clock / reset
    logic PCLK;
    //logic PRESETn;
   
    // Instantiate apb_uart_if
    apb_uart_if apb_if(
        .PCLK (PCLK)
        //.PRESETn(PRESETn)
    );

    // Instantiate sync_FIFO DUT
    Sync_FIFO dut (

    .PCLK          (PCLK),
    .PRESETn       (apb_if.PRESETn),

    .PADDR         (apb_if.PADDR),
    .PPROT         (apb_if.PPROT),
    .PSEL          (apb_if.PSEL),
    .PENABLE       (apb_if.PENABLE),
    .PWRITE        (apb_if.PWRITE),
    .PWDATA        (apb_if.PWDATA),
    .PSTRB         (apb_if.PSTRB),

    .PREADY        (apb_if.PREADY),
    .PRDATA        (apb_if.PRDATA),
    .PSLVERR       (apb_if.PSLVERR),

    .full          (apb_if.full),
    .empty         (apb_if.empty),

    .uart_baud_div (apb_if.uart_baud_div),
    .uart_tx_o     (apb_if.uart_tx_o),
    .uart_tx_busy  (apb_if.uart_tx_busy),
    .uart_tx_done  (apb_if.uart_tx_done)

);

//generate clock
    initial begin
        PCLK=1'b0;
        forever begin
            #5;
            PCLK=~PCLK;
        end
    end

//generate reset
    initial begin
        /*PRESETn = 1'b0;
        apb_if.uart_baud_div = 16'd4;
        repeat (5)
            @(posedge PCLK);
        PRESETn = 1'b1;*/
        apb_if.uart_baud_div = 16'd4;
        apb_if.apply_reset(5);
    end

//initial APB signals
    initial begin
        apb_if.PADDR   = '0;
        apb_if.PPROT   = '0;
        apb_if.PSEL    = 1'b0;
        apb_if.PENABLE = 1'b0;
        apb_if.PWRITE  = 1'b0;
        apb_if.PWDATA  = '0;
        apb_if.PSTRB   = '0;
    end

//set virtual if and start UVM test
    initial begin
        uvm_config_db #(virtual apb_uart_if)::set(null,"*","vif",apb_if);
        run_test();
    end

endmodule