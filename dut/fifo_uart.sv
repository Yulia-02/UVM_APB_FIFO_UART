module Sync_FIFO #(
    parameter WIDTH = 8,//每一项数据宽度为8bit
    parameter MAX_DEPTH = 256//物理上最多可以存储256个数据
)(
    // AMBA 4.0 APB Interface
    input  logic        PCLK,
    input  logic        PRESETn,
    input  logic [31:0] PADDR,//0表示寄存器区域，1表示FIFO数据区域
    input  logic [2:0]  PPROT,//protction
    input  logic        PSEL,//事务选择
    input  logic        PENABLE,//执行读写
    input  logic        PWRITE,//读写方向
    input  logic [31:0] PWDATA,//写数据
    input  logic [3:0]  PSTRB,//byte enable
    output logic        PREADY,//完成响应
    output logic [31:0] PRDATA,//读数据
    output logic        PSLVERR,//错误响应

    // FIFO output signals
    output logic full,
    output logic empty,

    //UART interface
    output logic uart_tx_o,//串型输出
    output logic uart_tx_busy,//正在发送
    output logic uart_tx_done,//一阵发送完成脉冲

    //UART configuration
    input logic [15:0] uart_baud_div//一个UART bit持续几个PCLK

);

// register block
logic [31:0] reg_block [7:0]; // 8 registers, each 32-bit
logic [31:0] status_reg; // the combinational status reg
/*
    bit 0: depth = 8
    bit 1: depth = 16
    bit 2: depth = 32
    bit 3: depth = 64
    bit 4: depth = 128
    bit 5: depth = 256
*/
logic [5:0] depth_sel_field;
// memory
logic [WIDTH - 1 : 0] mem [MAX_DEPTH - 1 : 0];//默认logic [7:0] mem [255:0]
logic [$clog2(MAX_DEPTH):0] fifo_depth;
// pointer counter记录FIFO中目前有多少个有效数据
logic [$clog2(MAX_DEPTH):0] count;
// pointer
logic [$clog2(MAX_DEPTH)-1:0] w_ptr, r_ptr;
// internal signals --- reg signals
logic reg_wr_en;
logic reg_rd_en;
logic [3:0] reg_addr;
// logic [31:0] reg_wr_data;
// internal signals --- fifo signals
logic w_ready;
logic w_valid;
logic r_ready;
logic r_valid;
// internal signals --- flags
logic addr_valid;

//UART internal signals
logic uart_tx_start;
logic [WIDTH-1:0] uart_tx_data;

//FIFO-to-UART handshake
logic fifo_to_uart_fire;

// mapping APB signals to internal reg signals
always_comb begin
    reg_wr_en = PSEL & PWRITE & PENABLE & ~PADDR[31] & addr_valid;
    reg_rd_en = PSEL & ~PWRITE & PENABLE & ~PADDR[31] & addr_valid;
    //reg_addr = (PADDR >> 2) & 4'b1111; //每个寄存器占 4 byte，地址除以4得到寄存器编号
    reg_addr = PADDR[5:2]; //寄存器是 4 Byte 对齐，PADDR[1:0] 永远是 00，真正表示寄存器编号的是 PADDR[5:2]
    /*
    PADDR=0x00 → reg_addr=0
    PADDR=0x04 → reg_addr=1
    PADDR=0x08 → reg_addr=2
    PADDR=0x0C → reg_addr=3
    PADDR=0x10 → reg_addr=4
    PADDR=0x14 → reg_addr=5
    PADDR=0x18 → reg_addr=6
    PADDR=0x1C → reg_addr=7
    PADDR=0x20 → reg_addr=8 //status_reg
    */
end

// mapping APB signals to internal fifo signals 
always_comb begin
    w_valid = PSEL & PWRITE & PENABLE & PADDR[31] & addr_valid;
    r_ready = !uart_tx_busy && !uart_tx_start;//UART不忙，并且当前没有正在产生tx_start脉冲
end

//FIFO byte is accepted by UART
assign fifo_to_uart_fire = r_ready && r_valid;

// address valid flag driver
always_comb begin
  if (PADDR[30:0] <= 32'h0000_0020) // This saves most of resources, bit 31 can be either 1 or 0
    addr_valid = 1'b1;
  else
    addr_valid = 1'b0;
end

// APB output signals driver
always_comb begin
    PREADY = 1; // APB slave永远不插入等待周期，每一个access phase都立即完成
    PSLVERR = ~addr_valid;
end

// reg fields
always_comb begin
    case (reg_block[0])//使用one-hot编码选择FIFO深度
        32'h1: depth_sel_field = 0;
        32'h2: depth_sel_field = 1;
        32'h4: depth_sel_field = 2;
        32'h8: depth_sel_field = 3;
        32'h10: depth_sel_field = 4;
        32'h20: depth_sel_field = 5;
        default: depth_sel_field = 0; // default to 8 if invalid config
    endcase
    fifo_depth = 8 << depth_sel_field;
    /*
    reg_block[0] = 0x8
    depth_sel_field = 3
    fifo_depth = 8 << 3 = 8 * 8 = 64
    */
end

// reg write
always_ff @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        reg_block[0] <= {31'd0, 1'd1}; // depth reg, default depth = 8
        reg_block[1] <= {32'd0}; // reserved
        reg_block[2] <= {32'd0}; // reserved
        reg_block[3] <= {32'd0}; // reserved
        reg_block[4] <= {32'd0}; // reserved
        reg_block[5] <= {32'd0}; // reserved
        reg_block[6] <= {32'd0}; // reserved
        reg_block[7] <= {32'd0}; // reserved
    end else if(reg_wr_en && PREADY) begin
        case (reg_addr)
            0: if(count == 0) begin//因为reg[0]控制fifo深度，所以只有FIFO为空时才可以修改reg_block[0]
                if(PSTRB[0]) reg_block[0][ 7: 0] <= PWDATA[ 7: 0];
                if(PSTRB[1]) reg_block[0][15: 8] <= PWDATA[15: 8];
                if(PSTRB[2]) reg_block[0][23:16] <= PWDATA[23:16];
                if(PSTRB[3]) reg_block[0][31:24] <= PWDATA[31:24];
            end
            default: begin
                if(PSTRB[0]) reg_block[reg_addr][ 7: 0] <= PWDATA[ 7: 0];
                if(PSTRB[1]) reg_block[reg_addr][15: 8] <= PWDATA[15: 8];
                if(PSTRB[2]) reg_block[reg_addr][23:16] <= PWDATA[23:16];
                if(PSTRB[3]) reg_block[reg_addr][31:24] <= PWDATA[31:24];
            end
        endcase
    end
    // else: when address is invalid, latch original data
end

//状态寄存器
always_comb begin
    status_reg[31:11] = 0;
    status_reg[10:2] = count;
    status_reg[1] = full;
    status_reg[0] = empty;
end

// APB read reg
always_comb begin
    if(reg_rd_en)
        if(reg_addr <= 7) begin // reg0 - reg7
            // PRDATA = PADDR;
            PRDATA = reg_block[reg_addr];
        end else if(reg_addr == 8) begin // reg8
            PRDATA = status_reg;
            // PRDATA = 32'hDEAD_BEEF;
        end else begin
            PRDATA = 32'd0; // invalid address
        end
    // APB read fifo
    else if(PSEL && !PWRITE && PENABLE && PADDR[31] && addr_valid)
        PRDATA = { {(32-WIDTH){1'b0}}, mem[r_ptr] };
    else
        PRDATA = 32'd0; // if invalid address
end

// fifo write
always_ff @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        w_ptr <= 0;
    end else if(w_ready && w_valid) begin
        if(PSTRB[0]) mem[w_ptr] <= PWDATA;
        if(w_ptr == fifo_depth - 1)
            w_ptr <= 0;
        else
            w_ptr <= w_ptr + 1;
    end
    //else: when address is invalid, latch original data
end

// fifo read --- update r_ptr
always_ff @( posedge PCLK or negedge PRESETn ) begin
    if(!PRESETn) begin
        r_ptr <= 0;
    end else if(fifo_to_uart_fire) begin//只有数据真正交给UART时，读指针才前进
        if(r_ptr == fifo_depth - 1)
            r_ptr <= 0;
        else
            r_ptr <= r_ptr + 1;
    end
end

// update var count
always_ff @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        count <= 0;
    end else begin
        case ({w_ready && w_valid, fifo_to_uart_fire})
            2'b10: count <= count + 1; // write only
            2'b01: count <= count - 1; // read only
            2'b11: count <= count; // read write together
            default: count <= count;   // no change or simultaneous read/write
        endcase
    end
end

// empty or full
always_comb begin    
    empty = (count == 0);
    full = (count == fifo_depth);
    w_ready = !full;
    r_valid = !empty;
end

//FIFO-to-UART bridge
always_ff @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        uart_tx_start <= 1'b0;
        uart_tx_data <='0;
    end else begin
        uart_tx_start <= 1'b0;

        if(fifo_to_uart_fire) begin
            uart_tx_data <= mem[r_ptr];//锁存FIFO头部数据
            uart_tx_start <= 1'b1;//UART开始发送
        end
    end
end

//UART TX
uart_tx #(
    .DATA_WIDTH(WIDTH)
) u_uart_tx (
    .clk(PCLK),
    .rst_n(PRESETn),
    .tx_start(uart_tx_start),
    .tx_data(uart_tx_data),
    .baud_div(uart_baud_div),
    .tx_busy(uart_tx_busy),
    .tx_done(uart_tx_done),
    .tx_o(uart_tx_o)
);

// assertions
`ifdef ASSERT_ON
property p_no_write_when_full;
    @(posedge PCLK) disable iff (!PRESETn)
        w_valid |=> !full;
endproperty

assert property (p_no_write_when_full)
    else $error("[ASSERT FAIL]: Write when FIFO is full!");

property p_no_read_when_empty;
    @(posedge PCLK) disable iff (!PRESETn)
        !(r_ready && empty)
endproperty
assert property (p_no_read_when_empty) 
    else $error("[ASSERT FAIL]: Read when FIFO is empty!");

// assert property (@(posedge PCLK) disable iff (!PRESETn) w_ptr < DEPTH) 
//     else $fatal("[ASSERT_FAIL], w_ptr overflow!");

// assert property (@(posedge PCLK) disable iff (!PRESETn) r_ptr < DEPTH) 
//     else $fatal("[ASSERT_FAIL], r_ptr overflow!"); 
`endif
endmodule
