class apb_write_sequence extends uvm_sequence #(apb_transaction);
  //Sequence 属于临时对象，不是长期运行的组件
  `uvm_object_utils(apb_write_sequence)

   bit [7:0] data;
   bit [31:0] target_addr = 32'h8000_0000;

   function new (string name="apb_write_sequence");
      super.new(name);
   endfunction

   //the actual stimulus lives entirely inside body()
    task body();
    
      //UVM父类里准备好了一个名为req的句柄，类型是apb_transaction，所以通常不需要再自己写一遍apb_transaction req
      //apb_transaction req;
      
      //使用factory创建apb_transaction对象
      req = apb_transaction::type_id::create("req");

      //向sequencer申请发送这个item
      start_item(req);
      
      //获得发送权后随机化transaction
      assert (req.randomize() with {
      write == 1'b1;
      //addr == 32'h8000_0000;
      addr == target_addr;
      wdata[31:8]== 24'd0;
      wdata[7:0] == data;
      strb == 4'b0001;
      prot == 3'b000;
      })
    else
      `uvm_fatal("RAND_FAIL", "APB transaction randomization failed")
      
      //将填写完成的item交给sequencer/driver
      finish_item(req);

   endtask

endclass
