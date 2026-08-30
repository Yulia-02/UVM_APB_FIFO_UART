`timescale 1ns/1ps

module fifo_uart_tb;

    parameter DATA_WIDTH = 8;

    logic        PCLK;
    logic        PRESETn;
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

    logic        full;
    logic        empty;

    logic [15:0] uart_baud_div;
    logic        uart_tx_o;
    logic        uart_tx_busy;
    logic        uart_tx_done;

    logic [7:0] received_data;

    Sync_FIFO #(
        .WIDTH(DATA_WIDTH),
        .MAX_DEPTH(256)
    ) dut (
        .PCLK          (PCLK),
        .PRESETn       (PRESETn),
        .PADDR         (PADDR),
        .PPROT         (PPROT),
        .PSEL          (PSEL),
        .PENABLE       (PENABLE),
        .PWRITE        (PWRITE),
        .PWDATA        (PWDATA),
        .PSTRB         (PSTRB),

        .PREADY        (PREADY),
        .PRDATA        (PRDATA),
        .PSLVERR       (PSLVERR),

        .full          (full),
        .empty         (empty),

        .uart_baud_div (uart_baud_div),
        .uart_tx_o     (uart_tx_o),
        .uart_tx_busy  (uart_tx_busy),
        .uart_tx_done  (uart_tx_done)
    );

    initial begin
        PCLK = 1'b0;
        forever #5 PCLK = ~PCLK;
    end

    //driver
    task automatic apb_write_fifo(
        input logic [DATA_WIDTH-1:0] data
    );
    begin
        @(negedge PCLK);

        PADDR   = 32'h8000_0000;//PADDR[31]=1 DUT判断在FIFO数据空间
        PWRITE  = 1'b1;//APB write
        PWDATA  = {{(32-DATA_WIDTH){1'b0}}, data};//32-bit data
        //PWDATA 是 32 位，共有 4 个字节，PSTRB[1] 对应 PWDATA[15:8]，PSTRB[2] 对应 PWDATA[23:16]，PSTRB[3] 对应 PWDATA[31:24]
        PSTRB   = 4'b0001;//字节使能信号，PWDATA[7:0]有效
        PSEL    = 1'b1;
        PENABLE = 1'b0;//setup

        @(negedge PCLK);
        PENABLE = 1'b1;

        //w_valid = PSEL & PWRITE & PENABLE & PADDR[31] & addr_valid

        wait(PREADY == 1'b1);//等待DUT表示访问完成

        @(negedge PCLK);

        //return to free status
        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PADDR   = 32'd0;
        PWDATA  = 32'd0;
        PSTRB   = 4'd0;

        $display("[%0t] APB wrote FIFO data = 0x%02h",
                 $time, data);
    end
    endtask

    //monitor
    task automatic receive_uart_byte(
        output logic [DATA_WIDTH-1:0] data
    );
    begin
        data = '0;

        // Wait for start-bit falling edge
        @(negedge uart_tx_o);

        // Move to the middle of the start bit
        repeat (uart_baud_div / 2)
            @(posedge PCLK);

        if (uart_tx_o !== 1'b0)
            $error("[%0t] Invalid UART start bit", $time);

        // Move from middle of start bit to middle of data bit 0
        repeat (uart_baud_div)
            @(posedge PCLK);

        // Sample data bits LSB first
        for (int i = 0; i < DATA_WIDTH; i++) begin
            data[i] = uart_tx_o;
            repeat (uart_baud_div)
                @(posedge PCLK);
        end

        // At this point we are at the middle of stop bit
        if (uart_tx_o !== 1'b1)
            $error("[%0t] Invalid UART stop bit", $time);

        $display("[%0t] UART decoded data = 0x%02h",
                 $time, data);
    end
    endtask

    initial begin
        PRESETn       = 1'b0;
        PADDR         = 32'd0;
        PPROT         = 3'd0;
        PSEL          = 1'b0;
        PENABLE       = 1'b0;
        PWRITE        = 1'b0;
        PWDATA        = 32'd0;
        PSTRB         = 4'd0;
        uart_baud_div = 16'd4;

        repeat (3) @(posedge PCLK);

        @(negedge PCLK);
        PRESETn = 1'b1;

        repeat (2) @(posedge PCLK);

        fork
            apb_write_fifo(8'h55);

            begin
                receive_uart_byte(received_data);

                if (received_data !== 8'h55) begin
                    $error(
                        "FAIL: expected 0x55, received 0x%02h",
                        received_data
                    );
                end else begin
                    $display(
                        "PASS: expected and received data = 0x55"
                    );
                end
            end
        join

        repeat (10) @(posedge PCLK);

        $display("[%0t] Test finished", $time);
        $finish;
    end

endmodule