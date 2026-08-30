//two different analysis implementations
`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_uart)

class apb_uart_scoreboard extends uvm_scoreboard;
   //factory
   `uvm_component_utils(apb_uart_scoreboard)

    //reset-aware
   virtual apb_uart_if vif;

   //two monitor inputs
   uvm_analysis_imp_apb #(apb_transaction, apb_uart_scoreboard) apb_imp;
   uvm_analysis_imp_uart #(uart_transaction, apb_uart_scoreboard) uart_imp;

   //expected queue用来暂存apb monitor发来的数据
   bit [7:0] expected_queue[$];//队列长度不固定，可以动态增加或减少

   int status_read_count = 0;
   int depth_read_count = 0;

   //constructor
   function new(string name = "apb_uart_scoreboard", uvm_component parent = null);
    super.new(name, parent);
   endfunction

   //build phase
   virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_imp=new("apb_imp",this);
    uart_imp=new("uart_imp",this); 

    if (!uvm_config_db #(virtual apb_uart_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("NO_VIF","Scoreboard could not get virtual interface")
        end
   endfunction

   //receive APB transaction
    function void write_apb(apb_transaction tr);
        bit [7:0] expected_depth_cfg;

        if(tr.write&&tr.addr==32'h8000_0000)begin//FIFO地址为32'h8000_0000,写操作
            expected_queue.push_back(tr.wdata[7:0]);//把APB monitor看到的低8bit数据放到队尾
            `uvm_info("SCOREBOARD",$sformatf("Expected data pushed:0x%02h",tr.wdata[7:0]),UVM_LOW)
        end
        //read status
        else if (!tr.write&&tr.addr==32'h0000_0020) begin

            status_read_count++;
            if(status_read_count==1)begin

                if (tr.rdata==32'h0000_0001) begin//count=0,empty=1,full=0
                    `uvm_info("STATUS_TEST",$sformatf("PASS: status register=0x%08h",tr.rdata),UVM_LOW)
                end
                else begin
                    `uvm_error("STATUS_TEST",$sformatf("FAIL: expected status=0x00000001,actual=0x%08h",tr.rdata))
                end
            end

            else if (status_read_count==2)begin
                if((tr.rdata[10:2]>0)&&(tr.rdata[1]==1'b0)&&(tr.rdata[0]==1'b0))begin
                    `uvm_info("STATUS_TEST",$sformatf("PASS after write:count=%0d full=%0b empty=%0b raw=0x%08h",tr.rdata[10:2],tr.rdata[1],tr.rdata[0],tr.rdata),UVM_LOW)
            end
        end
        end
        
        //invalid APB address
        else if (tr.write && tr.addr == 32'h0000_0040) begin

            if (tr.slverr == 1'b1) begin
            `uvm_info("INVALID_ADDR_TEST","PASS: PSLVERR asserted for invalid APB address",UVM_LOW)
            end

            else begin
            `uvm_error("INVALID_ADDR_TEST", "FAIL: PSLVERR was not asserted for invalid APB address")
            end
        end

        //depth config
        else if (!tr.write&&tr.addr==32'h0000_0000) begin
            depth_read_count++;

            case(depth_read_count)
                1: expected_depth_cfg = 8'h01;
                2: expected_depth_cfg = 8'h02;
                3: expected_depth_cfg = 8'h04;
                4: expected_depth_cfg = 8'h08;
                5: expected_depth_cfg = 8'h10;
                6: expected_depth_cfg = 8'h20;
                default: expected_depth_cfg=8'h00;
            endcase

            if(tr.rdata[7:0]==expected_depth_cfg)begin
                `uvm_info("DEPTH_TEST",$sformatf("PASS:expected=0x%02h,actual=0x%02h",expected_depth_cfg,tr.rdata[7:0]),UVM_LOW)
            end
            else begin
                `uvm_error("DEPTH_TEST",$sformatf("FAIL:expected=0x%02h,actual=0x%02h",expected_depth_cfg,tr.rdata[7:0]))
            end
            end
    endfunction

    
    //receive UART transaction
    function void write_uart(uart_transaction tr);
    bit [7:0] expected;
    if(expected_queue.size()==0)begin
        `uvm_error("SCOREBOARD",$sformatf("Received UART data 0x%02h, but expected queue is empty",tr.data))
        return;//不再继续
    end

    expected = expected_queue.pop_front();//从expected_queue队列里拿出来的一个字节

    if(expected==tr.data)begin//tr.data是uart monitor从uart_tx_o上解码出来的8-bit数据
        `uvm_info("SCOREBOARD",$sformatf("PASS:expected=0x%02h,actual=0x%02h",expected,tr.data),UVM_LOW)
    end
    else begin
        `uvm_error("SCOREBOARD",$sformatf("FAIL:expected=0x%02h,actual=0x%02h",expected,tr.data))
    end
    endfunction

    // Check phase
    virtual function void check_phase(uvm_phase phase);

        super.check_phase(phase);
        // At the end of simulation every expected byte should already have a matching UART transaction.
        if (expected_queue.size() != 0) begin
            `uvm_error("SCOREBOARD",$sformatf("Simulation ended with %0d unmatched expected UART byte(s)",expected_queue.size()))
        end
        else begin
            `uvm_info("SCOREBOARD","All expected UART data were successfully matched",UVM_LOW)
        end
    endfunction
        //reset handling
        virtual task run_phase(uvm_phase phase);
            forever begin
            // 等待 reset 被 assert
            @(negedge vif.PRESETn);
            // 清掉 reset 前还没有完成匹配的 expected data
            expected_queue.delete();
            `uvm_info("SCOREBOARD","Reset detected: expected queue cleared",UVM_LOW)
             end
        endtask

endclass