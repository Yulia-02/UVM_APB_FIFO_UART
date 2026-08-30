interface apb_uart_if(
    input logic PCLK
);
    logic PRESETn;
    
    //APB interface
    logic [31:0] PADDR;
    logic [2:0]  PPROT;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PWDATA;
    logic [3:0]  PSTRB;
    logic        PREADY;
    logic [31:0] PRDATA;
    logic        PSLVERR;

    // FIFO status
    logic full;
    logic empty;

    //UART interface
    logic        uart_tx_o;
    logic        uart_tx_busy;
    logic        uart_tx_done;
    logic [15:0] uart_baud_div;


    //clocking block设置时序

    //modport管理权限

    task apply_reset(int cycles=5);
        PRESETn=1'b0;

        repeat(cycles)
            @(posedge PCLK);
        PRESETn=1'b1;

    endtask

    
endinterface