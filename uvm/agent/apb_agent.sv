class apb_agent extends uvm_agent;
//factory
`uvm_component_utils(apb_agent)

//construction
function new (string name="apb_agent",uvm_component parent=null);
   super.new(name,parent);
endfunction

//handle
apb_monitor m_monitor;
apb_driver m_driver;
apb_sequencer m_sequencer;

//build phase
virtual function void build_phase (uvm_phase phase);
  super.build_phase (phase);

  if(get_is_active()==UVM_ACTIVE)begin
    m_sequencer=apb_sequencer::type_id::create("m_sequencer",this);
    m_driver=apb_driver::type_id::create("m_driver",this);
  end
    m_monitor=apb_monitor::type_id::create("m_monitor",this);
endfunction

//connect phase
virtual function void connect_phase(uvm_phase phase);
 super.connect_phase(phase);

 if(get_is_active()==UVM_ACTIVE)begin
   m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
 end
endfunction
endclass