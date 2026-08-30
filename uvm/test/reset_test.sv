class reset_test extends uvm_test;
    `uvm_component_utils(reset_test)

    apb_uart_env m_env;

    function new(string name="reset_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_env=apb_uart_env::type_id::create("m_env",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_write_sequence seq;
        int timeout_count;

        phase.raise_objection(this);

        //write several bytes before reset
        seq=apb_write_sequence::type_id::create("seq_11");
        seq.target_addr = 32'h8000_0000;
        seq.data=8'h11;
        seq.start(m_env.m_agent.m_sequencer);

        seq=apb_write_sequence::type_id::create("seq_22");
        seq.target_addr = 32'h8000_0000;
        seq.data=8'h22;
        seq.start(m_env.m_agent.m_sequencer);

        seq=apb_write_sequence::type_id::create("seq_33");
        seq.target_addr=32'h8000_0000;
        seq.data=8'h33;
        seq.start(m_env.m_agent.m_sequencer);

        //wait until UART is actively transmitting
        timeout_count=0;

        while((m_env.m_monitor.vif.uart_tx_busy!=1'b1)&&(timeout_count<100))begin
            @(posedge m_env.m_monitor.vif.PCLK);
            timeout_count++;
        end

        if(m_env.m_monitor.vif.uart_tx_busy!=1'b1)begin
            `uvm_error("RESET_TEST","UART did not become busy before timeout")
        end
        else begin
            `uvm_info("RESET_TEST","UART is active, asserting reset now",UVM_LOW);
        end

        //assert reset during UART transmission
        m_env.m_monitor.vif.apply_reset(3);
        
        //check reset state
        if(m_env.m_monitor.vif.empty==1'b1)
            `uvm_info("RESET_TEST","PASS:FIFO empty after reset",UVM_LOW)
            else 
            `uvm_error("RESET_TEST","FAIL:FIFO not empty after reset")

            if(m_env.m_monitor.vif.full==1'b0)
             `uvm_info("RESET_TEST","PASS:FIFO deassered after reset",UVM_LOW)
            else 
             `uvm_error("RESET_TEST","FAIL:FIFO full still asserted after reset")

            if(m_env.m_monitor.vif.uart_tx_busy==1'b0)
             `uvm_info("RESET_TEST","PASS: UART not busy after reset",UVM_LOW)
            else 
             `uvm_error("RESET_TEST","FAIL: UART still busy after reset")
            
            if(m_env.m_monitor.vif.uart_tx_o==1'b1)
             `uvm_info("RESET_TEST","PASS:UART TX returned to idle high",UVM_LOW)
            else 
             `uvm_error("RESET_TEST","FAIL:UART TX not idle after reset")

            //verify DUT can recover after reset
            seq=apb_write_sequence::type_id::create("seq_AA");
            seq.target_addr=32'h8000_0000;
            seq.data=8'hAA;
            seq.start(m_env.m_agent.m_sequencer);

            //wait until post-reset byte is fully checked
            timeout_count=0;

            while((m_env.m_scoreboard.expected_queue.size!=0)&&(timeout_count<500))begin
                @(posedge m_env.m_monitor.vif.PCLK);
                timeout_count++;
            end

            if(m_env.m_scoreboard.expected_queue.size()==0)begin
                `uvm_info("RESET_TEST","PASS:DUT recovered and post-reset UART data matched",UVM_LOW)
            end
            else begin
                `uvm_error("RESET_TEST","FAIL:POST-reset UART transaction did not complete")
            end

            @(posedge m_env.m_monitor.vif.PCLK);
            phase.drop_objection(this);
    endtask
endclass

            

