`timescale 1ns/1ps

module uart_tx_tb;
   parameter DATA_WIDTH = 8;

   logic clk;
   logic rst_n;
   logic tx_start;
   logic [DATA_WIDTH-1:0] tx_data;
   logic [15:0] baud_div;

   logic tx_busy;
   logic tx_done;
   logic tx_o;

   //DUT
   uart_tx #(
      .DATA_WIDTH(DATA_WIDTH)
   ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .tx_start(tx_start),
      .tx_data(tx_data),
      .baud_div(baud_div),
      .tx_busy(tx_busy),
      .tx_done(tx_done),
      .tx_o(tx_o)
   );
   
   initial begin
      clk = 1'b0;
      forever #5 clk = ~clk;
   end

   task automatic send_byte(input logic [DATA_WIDTH-1:0] data);
       begin
         wait(tx_busy == 1'b0);//等待空闲

         @(negedge clk);
         tx_data = data;//在下降沿设置tx_data
         tx_start = 1'b1;//tx_start拉高
//下一个上升沿DUT接收数据
         @(negedge clk);
         tx_start = 1'b0;//下一个下降沿tx_start清零
//DUT发送start data stop
         wait(tx_done == 1'b1);
         
         $display("[%0t] UART transmitted data = 0x%0h", $time, data);

       end
   endtask

   initial begin
      rst_n = 1'b0;
      tx_start = 1'b0;
      tx_data = '0;

      baud_div = 16'd4;

      repeat (3) @(posedge clk);

      @(negedge clk);
      rst_n = 1'b1;

      repeat (2) @(posedge clk);

      send_byte(8'h00);
      //repeat (2) @(posedge clk);

      send_byte(8'hFF);
      //repeat (2) @(posedge clk);
       
      send_byte(8'hAA);
      send_byte(8'h55);

      repeat (10) @(posedge clk);

      $display("[%0t] Test finished", $time);
      $finish;
   end

      initial begin
         $dumpfile("uart_tx_tb.vcd");
         $dumpvars(0, uart_tx_tb);
      end
endmodule