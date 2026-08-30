class apb_sequencer extends uvm_sequencer #(apb_transaction);

//factory
`uvm_component_utils(apb_sequencer)

//new
function new (string name="apb_sequencer",uvm_component parent=null);
    super.new(name,parent);
endfunction

endclass
    


