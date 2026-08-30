class uart_monitor extends uvm_monitor;
   
//factory
`uvm_component_utils (uart_monitor)

//virtual interface
virtual apb_uart_if vif;

//analysis port
uvm_analysis_port #(uart_transaction) ap;

//constructor
function new (string name="uart_monitor", uvm_component parent=null);
    super.new(name,parent);
endfunction

//build phase
virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);

//创建monitor对外发送transaction的port
    ap = new("ap",this);

//获得monitor要观察的interface
    if (!uvm_config_db #(virtual apb_uart_if)::get(this, "", "vif", vif))begin
       `uvm_error(get_type_name(),"Didn't get handle to virtual interface")
    end
endfunction

//run phase
virtual task run_phase (uvm_phase phase);
    uart_transaction tr;
    logic [7:0] received_data;
    int unsigned monitor_baud_div;
    bit frame_complete;//捕获到的UART frame是否完整有效，可以交给scoreboard

    forever begin
        received_data ='0;
        frame_complete=1'b0;

        wait(vif.PRESETn==1'b1);

        if (vif.uart_baud_div == 16'd0)
            monitor_baud_div = 1;
        else
            monitor_baud_div = vif.uart_baud_div;

        `uvm_info("UART_MON_DEGUB","Waiting for UART state edge",UVM_LOW)

        @(negedge vif.uart_tx_o);

        `uvm_info("UART_MON_DEBUG","Detected UART start edge",UVM_LOW)

    fork
        begin
            //thread1 正常解码UART frame
            repeat (monitor_baud_div/2)
                @(posedge vif.PCLK);

            // 改在 negedge 采样，避开 DUT 的 posedge 更新
            @(negedge vif.PCLK);

            if(vif.uart_tx_o !== 1'b0)//uart_tx_o=1表示UART处于空闲状态
                `uvm_error("UART_MON","Invalid UART start bit")
        
            repeat (monitor_baud_div)
                @(posedge vif.PCLK);

            for(int i=0; i<8; i++)begin

                // 在稳定区间采样
                @(negedge vif.PCLK);

                received_data[i]=vif.uart_tx_o;

                //等待uart_baud_div个上升沿
                repeat (monitor_baud_div)
                    @(posedge vif.PCLK);
            end

            // stop bit 也在 negedge 检查
            @(negedge vif.PCLK);   

            if(vif.uart_tx_o !==1'b1)
                `uvm_error("UART_MON","Invalid UART stop bit")

            frame_complete=1'b1;
        end
        //等待reset
        begin
            @(negedge vif.PRESETn);
                `uvm_info("UART_MON","Reset detected during UART frame-discard current frame",UVM_LOW)
        end

    join_any

    disable fork;//一个线程确定后把另一个线程kill

    if(frame_complete && vif.PRESETn)begin
        `uvm_info("UART_MON_DEBUG",$sformatf("Frame complete, data=0x%02h",received_data),UVM_LOW)
        //将采集到的数据以transaction的形式广播
        tr = uart_transaction::type_id::create("tr",this);
        tr.data=received_data;
        ap.write(tr);

    end
    else begin
        wait(vif.PRESETn==1'b1);
    end
    end
endtask
endclass