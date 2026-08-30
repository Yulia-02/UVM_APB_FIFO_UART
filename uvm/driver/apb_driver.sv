class apb_driver extends uvm_driver #(apb_transaction);
   
   // Register the driver with the UVM factory
   `uvm_component_utils(apb_driver) 

   // Virtual if handle
   virtual apb_uart_if vif;
   
   // Construction
   function new(string name="apb_driver", uvm_component parent = null);//new
      super.new(name, parent);
   endfunction

   // Build phase——get the virtual interface
   virtual function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     if (!uvm_config_db #(virtual apb_uart_if)::get(this, "", "vif", vif))begin
       `uvm_fatal(get_type_name(),"Didn't get handle to virtual interface")
     end
   endfunction

   // Run phase——main driver process
   virtual task run_phase(uvm_phase phase);
      apb_transaction tr;

      // Do not drive transactions during reset
      wait(vif.PRESETn == 1'b1);

      forever begin
         seq_item_port.get_next_item(tr);
         
         // APB setup phase
         @(negedge vif.PCLK);

         // Transaction fields -> actual APB if signals
         vif.PADDR <= tr.addr;
         vif.PWRITE <= tr.write;
         vif.PSTRB <= tr.strb;
         vif.PPROT <= tr.prot;
         vif.PWDATA <= tr.wdata;
         vif.PSEL <= 1'b1;
         vif.PENABLE <=1'b0;
      
         // APB access phase
         @(negedge vif.PCLK);
         vif.PENABLE <= 1'b1;

         // Wait for the slave to complete the transfer
         wait(vif.PREADY == 1'b1);

         // Keep Access phase active through a rising edge
         @(posedge vif.PCLK);

         // Capture DUT response
         tr.rdata = vif.PRDATA;
         tr.slverr = vif.PSLVERR;

         // Return bus to idle
         @(negedge vif.PCLK);

         vif.PSEL    <= 1'b0;
         vif.PENABLE <= 1'b0;  
         vif.PWRITE <= 1'b0;
         vif.PADDR  <= '0;
         vif.PWDATA <= '0;
         vif.PSTRB  <= '0;
         vif.PPROT  <= '0;

         seq_item_port.item_done();
      end
      
   endtask 
   
endclass