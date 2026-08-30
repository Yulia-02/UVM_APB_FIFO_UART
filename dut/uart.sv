module uart_tx #(
    parameter DATA_WIDTH = 8
)(
    input logic clk,
    input logic rst_n,
    input logic tx_start,
    input logic [DATA_WIDTH-1:0] tx_data,
    input logic [15:0] baud_div,      // 波特率分频器 baud divider

    output logic tx_busy,
    output logic tx_done,
    output logic tx_o
);
    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;
    
    localparam BIT_IDX_WIDTH = (DATA_WIDTH <= 1) ? 1 : $clog2(DATA_WIDTH);

    state_t state;

    logic [15:0] baud_cnt; //计时器
    logic [BIT_IDX_WIDTH-1:0] bit_idx; //位数
    logic [DATA_WIDTH-1:0] shift_reg; //缓存区
    logic [15:0] effective_baud_div;

    always_comb begin
        if (baud_div == 16'd0)
            effective_baud_div = 16'd1;
        else
            effective_baud_div = baud_div;
    end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        baud_cnt <= 16'd0;
        bit_idx <='0;
        shift_reg <= '0;
        tx_o <= 1'b1;
        tx_busy <= 1'b0;
        tx_done <= 1'b0;
    end else begin
        tx_done <= 1'b0;

        case (state)
            IDLE: begin
                tx_o <= 1'b1;
                tx_busy <= 1'b0;
                baud_cnt <= 16'd0;
                bit_idx <= '0;

                if (tx_start) begin
                    shift_reg <= tx_data;//将输入数据锁存进缓存区
                    tx_busy <= 1'b1;
                    state <= START;
                end
            end

            START: begin
                tx_o <= 1'b0;
                tx_busy <= 1'b1;

                if (baud_cnt == effective_baud_div-1'b1) begin
                    baud_cnt <= 16'd0;
                    state <= DATA;
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                end
            end
            
            DATA: begin
                tx_o <= shift_reg[bit_idx];  //bit_idx决定发哪一位
                tx_busy <= 1'b1;

                if(baud_cnt == effective_baud_div-1'b1) begin  //每一位保持baud_div个时钟
                    baud_cnt <= 16'd0;

                    if(bit_idx == DATA_WIDTH-1)begin
                        bit_idx <= '0;
                        state <= STOP;
                    end else begin
                        bit_idx <= bit_idx + 1'b1;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                end 
            end

            STOP: begin
                tx_o <= 1'b1;
                tx_busy <= 1'b1;

                if (baud_cnt == effective_baud_div-1'b1) begin
                    baud_cnt <= 16'd0;
                    tx_done <= 1'b1;
                    tx_busy <= 1'b0;
                    state <= IDLE;
                end

                else begin
                    baud_cnt <= baud_cnt + 1'b1;
                end
            end

            default: begin
                state <= IDLE;
                baud_cnt <= 16'd0;
                bit_idx <= '0;
                shift_reg <= '0;
                tx_o <= 1'b1;
                tx_busy <= 1'b0;
            end
        endcase
    end
end

endmodule
