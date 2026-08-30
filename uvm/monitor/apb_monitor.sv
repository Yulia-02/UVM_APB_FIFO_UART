class apb_monitor extends uvm_monitor;

//factory
   `uvm_component_utils(apb_monitor)
//virtual interface
   virtual apb_uart_if vif;
//analysis port
   uvm_analysis_port #(apb_transaction) ap;

//construction
   function new(string name="apb_monitor", uvm_component parent=null);
      super.new(name,parent);
   endfunction

//build phase
     virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
//创建monitor对外发送transaction的port
     ap=new("ap",this);
//获得monitor要观察的interface
     if (!uvm_config_db #(virtual apb_uart_if)::get(this, "", "vif", vif))begin
       `uvm_error(get_type_name(),"Didn't get handle to virtual interface")
     end
   endfunction

//run phase
   virtual task run_phase(uvm_phase phase);
      apb_transaction tr;
     forever begin
       @(posedge vif.PCLK);

       if(vif.PSEL&&vif.PENABLE&&vif.PREADY)begin
         tr = apb_transaction::type_id::create("tr", this);
         
           tr.addr=vif.PADDR;
           tr.write=vif.PWRITE;
           tr.prot=vif.PPROT;
           tr.wdata=vif.PWDATA;
           tr.strb=vif.PSTRB;
           tr.slverr=vif.PSLVERR;
           tr.rdata=vif.PRDATA;

           `uvm_info("APB_MON",$sformatf("MONITOR: addr=0x%08h write=%0b PRDATA=0x%08h tr.rdata=0x%08h",vif.PADDR,vif.PWRITE,vif.PRDATA,tr.rdata),UVM_LOW)
           //广播transaction
           ap.write(tr);
       end
     end
   endtask

endclass



