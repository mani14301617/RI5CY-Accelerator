


module cv32e40p_ml_ops(
    input  logic        ml_ops_enable_i,
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [31:0] mem_rd_data_i,
    input  logic [31:0] operand_a_addr_i,
    input  logic [31:0] operand_b_size_i,
    input  logic        loading_data_i,
    input  logic        ml_dotp_en_i,           
    input  logic        ml_relu_en_i,         
    input  logic        ml_sigmoid_en_i,     
    input  logic        ml_softmax_en_i,       
    input  logic        ml_matrixmult_en_i,    
    input  logic        ml_matrixadd_en_i,
    input  logic        ex_ready_i,
    //input  ml_opcode_e  ml_oper_i,
    output logic [31:0] reg_wr_data_o ,
    output logic [31:0] mem_wr_data_o,
    output logic [31:0] mem_addr_o,
    output logic        mem_rd_en_o,
    output logic        mem_wr_en_o,
    output logic        reg_wr_en_o,
    output logic        ml_op_done_o,
    output logic        ml_ready_o
);

logic [31:0] reg_wr_data;
logic        reg_wr_en;
logic        ml_ops_enable;
logic        RB_en;
logic [1:0]  load_count;
logic        ml_dotp_en;           
logic        ml_relu_en;         
logic        ml_sigmoid_en;     
logic        ml_softmax_en;       
logic        ml_matrixmult_en;    
logic        ml_matrixadd_en;
logic        loading_data;
logic [31:0] size[0:2];
logic [31:0] addr[0:2];
logic [4:0]count_16;
logic done_16;
logic done_16_delay1;
logic done_size1_delay1,done_size2_delay1;
logic load_en_delay1,load_en_delay2,load_en_delay3;
logic mem_rd_en,mem_wr_en;
logic ml_ready,ml_op_done;
logic [31:0]buffer_input,buffer_output;
logic buffer_full,buffer_empty,buffer_pop,buffer_push;
logic pop;
logic [4:0]count_to_buffer;
logic [31:0]count_size1,count_size2;
logic done_size1,done_size2;
logic [31:0]t_size1,t_size2;
logic last_buffer_batch;
logic dotp_result_ready;
logic dotp_load;


assign  ml_dotp_en        = ml_dotp_en_i;           
assign  ml_relu_en        = ml_relu_en_i;         
assign  ml_sigmoid_en     = ml_sigmoid_en_i;     
assign  ml_softmax_en     = ml_softmax_en_i;       
assign  ml_matrixmult_en  = ml_matrixmult_en_i;   
assign  ml_matrixadd_en   = ml_matrixadd_en_i;
assign  loading_data      = loading_data_i;
assign  ml_ops_enable     = ml_ops_enable_i;

 typedef enum logic [3:0] {
    RESET         = 4'b0000,  
    I_LOAD        = 4'b0001,  
    SET_ADDR      = 4'b0011, 
    LOAD_S        = 4'b0010,  
    LOAD_D        = 4'b0110,  
    SIGMOID_TAKE  = 4'b0111,
    SIGMOID_REST  = 4'b0101,  
    SIGMOID_GIVE  = 4'b0100,  
    DONE          = 4'b1100,
    DOTP_TAKE     = 4'b1110,
    DOTP_REST     = 4'b1111,
    DOTP_GIVE     = 4'b1010,
    SOFTMAX_TAKE  = 4'b1011
} oper_state_t;

oper_state_t oper_ns,oper_cs;

always_ff @(posedge clk_i or negedge rst_i) begin : load_addr // loading the size and address
    if (~rst_i) begin
        size[0] <= 0; size[1] <= 0;size[2] <= 0;
        addr[0] <= 0; addr[1] <= 0;addr[2] <= 0;
        load_count <= 0;
    end 
    else begin
      if(ml_ops_enable) begin
         if (loading_data) begin
            size[load_count] <= operand_b_size_i;
            addr[load_count] <= operand_a_addr_i;
            load_count <= load_count + 1;
               end 
         else if(ml_op_done)
            load_count <= 0;
         else begin
            size[load_count] <= size[load_count];
            addr[load_count] <= addr[load_count];
            load_count <= load_count;
            end
        end
    end
end

logic counter_en;
assign counter_en = (ml_dotp_en|ml_matrixmult_en|ml_matrixadd_en);
logic counter;

always_ff@(posedge clk_i or negedge rst_i) begin  : counter_
  if(~rst_i)
      counter<=0;
 
  else begin
      if(counter_en)
      counter<=counter+1;  
      else counter <= 0;
  end
end

logic counter_clk;

assign counter_clk = counter_en?counter:clk_i;

logic [31:0]mem_rd_addr;
logic [31:0]rd_addr1;
logic [31:0]rd_addr2;
logic [31:0]rd_addr_final;
logic load_en;
logic load_2;
assign load_2 = (load_count==2'b10);
assign minus_4 = done_16_delay1 | done_size1_delay1;

always_ff@(posedge counter_clk or negedge rst_i) begin : mem_addr1
   if(~rst_i) begin
    rd_addr1 <=0;
   end
   else begin
   if(ml_ops_enable) begin
     if(oper_cs == SET_ADDR) 
      rd_addr1 <= addr[0];
     else if(load_en) 
      rd_addr1 <= rd_addr1 + 4;
     else if(minus_4) 
      rd_addr1 <= rd_addr1 - 4;
     else if(ml_op_done)
      rd_addr1 <= 0;
     else 
      rd_addr1 <= rd_addr1 ;
    end
    else
     rd_addr1 <= 0;
   end
end

always_ff@(posedge counter_clk or negedge rst_i) begin : mem_addr2
   if(~rst_i) begin
    rd_addr2 <=0;
   end
   else begin
   if(ml_ops_enable) begin
     if(oper_cs == SET_ADDR) 
      rd_addr2 <= addr[1];
     else if(~counter_en)
      rd_addr2 <= 0;
     else if(load_en_delay2) 
      rd_addr2 <= rd_addr2 + 4;
     else if(minus_4) 
      rd_addr2 <= rd_addr2 - 4;
     else if(ml_op_done)
      rd_addr2 <= 0;
     else 
      rd_addr2 <= rd_addr2 ;
    end
    else
     rd_addr2 <= 0;
   end
end

logic [31:0] mem_addr;
//always_ff@(posedge clk_i or negedge rst_i) begin : mem_addr_out
//   if(~rst_i) 
//    mem_addr <= 0;
//   else begin
//    if(counter_en) 
//     mem_addr <= counter_clk?rd_addr2:rd_addr1;
//    else
//     mem_addr <=rd_addr1;
//   end
//end

assign mem_addr   = counter_en?(counter_clk?rd_addr2:rd_addr1):rd_addr1;
assign mem_addr_o = mem_wr_en?rd_addr_final:(mem_rd_en?mem_addr:32'b0);    
    
logic mem_wr;
assign mem_wr = (ml_relu_en|ml_sigmoid_en|ml_softmax_en|ml_matrixadd_en);

always_ff@(posedge counter_clk or negedge rst_i) begin : mem_addr_final
   if(~rst_i) begin
    rd_addr_final <=0;
   end
   else begin
   if(ml_ops_enable & mem_wr) begin
     if(oper_cs == SET_ADDR) 
      rd_addr_final <= addr[load_count - 1];
     else if(pop & ~buffer_full) 
      rd_addr_final <= rd_addr_final + 4;
     else if(ml_op_done)
      rd_addr_final <= 0;
     else 
      rd_addr_final <= rd_addr_final ;
    end
    else
     rd_addr_final <= 0;
   end
end

logic  [31:0]mem_wr_addr;
assign mem_wr_addr = mem_wr_en?rd_addr_final:32'h00000000;

always_ff@(posedge clk_i or negedge rst_i) begin : fsm_update
  if(~rst_i)
   oper_cs<=RESET;
  else if(ml_ops_enable)
   oper_cs<=oper_ns;
  else
   oper_cs<=RESET;
end


logic operator_en;
assign operator_en = (ml_dotp_en|ml_matrixmult_en|ml_matrixadd_en|ml_relu_en|ml_sigmoid_en|ml_softmax_en);

logic [31:0]bufA,bufB;
logic [31:0]mem_rd_data;
assign mem_rd_data = mem_rd_data_i;

always_ff@(posedge clk_i or negedge rst_i) begin : buffer_load_A
  if(~rst_i)
   bufA <= 0;
  else if(ml_ops_enable) begin
    if(load_en) begin
      if(counter_en) begin
        if(counter_clk)
          bufA <= mem_rd_data;
        else
          bufA <= bufA;
      end
      else 
       bufA <= mem_rd_data;
    end
    else
      bufA <= 0;
   end
   else
      bufA <= 0;
end

always_ff@(posedge clk_i or negedge rst_i) begin : buffer_load_B
  if(~rst_i)
   bufB <= 0;
  else if(ml_ops_enable) begin
    if(load_en_delay2) begin
      if(counter_en) begin
        if(~counter_clk)
          bufB <= mem_rd_data;
        else
          bufB <= bufB;
      end
      else 
       bufB <= 0;
    end
    else
      bufB <= 0;
   end
   else
      bufB <= 0;
end

logic sigmoid_enable,dotp_enable,relu_enable;
logic buffer_enable;
logic dotp_total_done;
always_comb begin : fsm
  oper_ns        = oper_cs;
  mem_rd_en      = 1'b0;
  mem_wr_en      = 1'b0;
  ml_ready       = 1'b1;
  ml_op_done     = 1'b0;
  load_en        = 1'b0;
  reg_wr_en      = 1'b0;
  //sigmoid_enable = 1'b0;
  //dotp_enable    = 1'b0;
  //relu_enable    = 1'b0;
  buffer_enable  = 1'b0;
  pop            = 1'b0; 
  case(oper_cs)
    
    RESET: begin
     if(loading_data)
      oper_ns = I_LOAD;
     else
      oper_ns = RESET;
    end

    I_LOAD: begin
     if(~loading_data)
      oper_ns = SET_ADDR;
     else
      oper_ns = I_LOAD;
    end

    SET_ADDR: begin
    ml_ready       = 1'b0;
     if(counter_en)
      oper_ns = LOAD_D;
     else
      oper_ns = LOAD_S;
    end

    LOAD_S: begin
     mem_rd_en      = 1'b1;
     ml_ready       = 1'b0;
     load_en        = 1'b1;

     if(ml_relu_en|ml_sigmoid_en)
      oper_ns = SIGMOID_TAKE;
     else
      oper_ns = SOFTMAX_TAKE;
     end
     
     SIGMOID_TAKE: begin 
      mem_rd_en      = 1'b1;
      ml_ready       = 1'b0;
      load_en        = 1'b1;
      //sigmoid_enable = 1'b1;
      buffer_enable  = 1'b1;
      if(done_16 | done_size1 )
      oper_ns = SIGMOID_REST;
      else
      oper_ns = SIGMOID_TAKE;
      end
      
      SIGMOID_REST: begin
       mem_rd_en       = 1'b0;
       load_en         = 1'b0;
       ml_ready        = 1'b0;
       //sigmoid_enable  = 1'b1;
       buffer_enable   = 1'b1;
       //if(done_size1_delay1 | done_16_delay1)
        // sigmoid_enable = 1'b0;

       if(buffer_full)
        oper_ns   = SIGMOID_GIVE;
       else
        oper_ns   = SIGMOID_REST;
        
      end
     
      SIGMOID_GIVE: begin
       mem_wr_en      = 1'b1;
       ml_ready       = 1'b0;
       pop            = 1'b1;
       buffer_enable   = 1'b1;
       if(buffer_empty & last_buffer_batch)
       oper_ns    = DONE;
       else if(buffer_empty)
       oper_ns    = SIGMOID_TAKE;
       else
       oper_ns    = SIGMOID_GIVE;
       end
       
       LOAD_D: begin
        mem_rd_en      = 1'b1;
        ml_ready       = 1'b0;
        load_en        = 1'b1;
        oper_ns        = DOTP_TAKE;
        end
        
       DOTP_TAKE: begin
        mem_rd_en      = 1'b1;
        ml_ready       = 1'b0;
        load_en        = 1'b1;
        if(dotp_total_done)
          oper_ns      = DOTP_REST;
        else
          oper_ns      = DOTP_TAKE;
       end
       
       DOTP_REST: begin
        mem_rd_en       = 1'b0;
        load_en         = 1'b0;
        ml_ready        = 1'b0;
        if(dotp_result_ready)
          oper_ns       = DOTP_GIVE;
        else 
          oper_ns       = DOTP_REST;
       end
       
       DOTP_GIVE: begin
        reg_wr_en       = 1'b1;
        ml_ready        = 1'b0;
        oper_ns         = DONE;
       end
       
       DONE: begin
       ml_op_done     = 1'b1;
       if(ex_ready_i) oper_ns = RESET;
       end
       default : begin
       oper_ns = RESET;
       end
   
   endcase
       
end 


logic [31:0]A,B;

assign A = bufA;
assign B = bufB;

logic [31:0]sigmoid_out,relu_out,dotp_out;


assign relu_enable    = load_en_delay2&ml_relu_en;
assign sigmoid_enable = load_en_delay2&ml_sigmoid_en;

sigmoid sig(
     .clk(clk_i),
     .rst_n(rst_i), 
     .enable(sigmoid_enable),
     .float_value(A), 
     .sig_mapped_value(sigmoid_out)
);

relu rel(
    .clk(clk_i),
    .rst_n(rst_i),
    .enable(relu_enable),
    .float_value(A),
    .relu_mapped_value(relu_out)
);



always_ff@(posedge counter_clk or negedge rst_i) begin : load_with_both_data
  if(~rst_i)
    dotp_load <= 0;
  else begin
    if(ml_dotp_en)
     dotp_load <= (oper_cs == DOTP_TAKE) ;
    else
     dotp_load <= 0;
  end
end
 
logic dotp_enable_delay1,dotp_enable_delay2,dotp_enable_delay3,dotp_enable_delay4;
always_ff@(posedge clk_i or negedge rst_i) begin 
  if(~rst_i) begin
    dotp_enable_delay1 <= 0;
    dotp_enable_delay2 <= 0;
    dotp_enable_delay3 <= 0;
    dotp_enable_delay4 <= 0;
  end
  else begin
     dotp_enable_delay1 <= dotp_enable ;
     dotp_enable_delay2 <= dotp_enable_delay1 ;
     dotp_enable_delay3 <= dotp_enable_delay2 ;
     dotp_enable_delay4 <= dotp_enable_delay3 ;
  end
end

assign dotp_enable = ml_dotp_en;

dotp  dot (
    .clk_half(counter_clk),
    .rst_n(rst_i),
    .load(dotp_load), 
    .enable(dotp_enable_delay3),
    .buf_a(A), 
    .buf_b(B),
    .out(dotp_out),
    .ready(dotp_result_ready)
    );
    
logic [1:0]dotp_no;
logic dotp_count_en;
logic [32:0]dotp_count;
logic [32:0]double_count_dotp;
assign double_count_dotp = {t_size1,1'b0};

always_ff@(posedge clk_i or negedge rst_i) begin : dotp_progress
  if(~rst_i) begin
    dotp_total_done <= 0;
  end
  else begin
    if(ml_dotp_en&&load_en) begin
       if(dotp_count == double_count_dotp)
         dotp_total_done <= 1;
       else
         dotp_total_done <= 0;
    end
    else
      dotp_total_done <= 0;
  end
end
    
always_ff@(posedge clk_i or negedge rst_i) begin : dotp_size_count
  if(~rst_i) begin
   dotp_count <= 0;
  end
  else begin
   if(ml_dotp_en&&load_en) begin
     if(dotp_total_done)
      dotp_count <= 0;
     else
      dotp_count <= dotp_count + 1;
   end
   else
     dotp_count <= 0;
  end
end
  
always_ff@(posedge clk_i or negedge rst_i) begin : load_delay //for the buffer to know when to start loading
  if(~rst_i) begin
   load_en_delay1<=0;
   load_en_delay2<=0;
   load_en_delay3<=0;
  end
  else begin
   load_en_delay1<=load_en;
   load_en_delay2<=load_en_delay1;
   load_en_delay3<=load_en_delay2;
  end
end



always_ff@(posedge counter_clk or negedge rst_i)  begin : counter_16  // loading in batches of 16 for certain functions
  if(~rst_i) begin
   count_16 <= 0;
   //done_16  <= 0;
  end
  else begin
   if(load_en) begin
     if(count_16[4]) begin
       count_16 <= 0;
      // done_16  <= 1;
     end
     else begin  
       count_16 <= count_16 + 1;
      // done_16  <= 0;
     end
   end
   else begin
      count_16 <= 0;
      //done_16  <= 0;
   end
  end
end

assign done_16 = (count_16[4]);


always_ff@(posedge counter_clk or negedge rst_i) begin : counter_16_delay
  if(~rst_i)
   done_16_delay1 <= 0;
  else
   done_16_delay1 <= done_16;
end

assign t_size1 = size[0];
assign t_size2 = size[1];

always_ff@(posedge counter_clk or negedge rst_i)  begin : counter_size1 // checking the total count according to the size
  if(~rst_i) begin
   count_size1 <= 0;
   done_size1  <= 0;
  end
  else if(ml_op_done | ~ml_ops_enable) begin
   count_size1 <= 0;
   done_size1  <= 0;
  end
  else begin
   if(load_en) begin
     if(count_size1 == t_size1) begin
       count_size1 <= 0;
       done_size1  <= 1;
     end
     else begin  
       count_size1 <= count_size1 + 1;
       done_size1  <= 0;
     end
   end
   else begin
      count_size1 <= count_size1;
      done_size1  <= 0;
   end
  end
end

always_ff@(posedge counter_clk or negedge rst_i)  begin : counter_size2  // checking the total count according to the size
  if(~rst_i) begin
   count_size2 <= 0;
   done_size2  <= 0;
  end
  else if(ml_op_done | ~ml_ops_enable) begin
   count_size2 <= 0;
   done_size2  <= 0;
  end
  else begin
   if(load_en & counter_en) begin
     if(count_size2 == t_size2) begin
       count_size2 <= 0;
       done_size2  <= 1;
     end
     else begin  
       count_size2 <= count_size2 + 1;
       done_size2  <= 0;
     end
   end
   else begin
      count_size2 <= count_size2;
      done_size2  <= 0;
   end
  end
end



always_ff@(posedge clk_i or negedge rst_i) begin : done_sizes_delay1 //for checking conditions  in the sigmoid_rest case
  if(~rst_i) begin
   done_size1_delay1 <=0;
   done_size2_delay1 <=0;
  end
  else begin
   done_size1_delay1 <= done_size1 ;
   done_size2_delay1 <= done_size2 ;
  end
end


assign buffer_input = ml_sigmoid_en?sigmoid_out:(ml_relu_en?relu_out:32'h00000000);
assign buffer_push = load_en_delay3;
assign buffer_pop  = pop;
 
fifo buffer(
    .clk(clk_i),
    .rst_n(rst_i),
    .enable(buffer_enable),
    .count_ext(count_to_buffer),
    .push(buffer_push), 
    .pop(buffer_pop),  
    .din(buffer_input),   
    .dout(buffer_output),  
    .full(buffer_full),    
    .empty(buffer_empty)
 
);

logic buffer_full_delay1;

always_ff@(posedge counter_clk or negedge rst_i) begin :  buffer_full_delay  //mainly for the final_addr increment
   if(~rst_i) 
    buffer_full_delay1 <= 0;
   else
    buffer_full_delay1 <= buffer_full;
end

logic count_manager_enable ;
logic cm_temp,cm_temp_delay1;

assign cm_temp = (oper_cs==SIGMOID_TAKE);
always_ff@(posedge counter_clk or negedge rst_i) begin : positive_edge_detector
  if(~rst_i)
   cm_temp_delay1 <= 0;
  else
   cm_temp_delay1<= cm_temp;
end

assign count_manager_enable = cm_temp&(~cm_temp_delay1);

logic cm_load;
assign cm_load = (oper_cs == SET_ADDR);



count_manager cm(
    .size(size[0]),                      
    .clk(counter_clk),             
    .rst(rst_i),       
    .enable(count_manager_enable), 
    .load(cm_load),
    .last_one(last_buffer_batch),     
    .count_to_buffer(count_to_buffer) 
);

logic reg_wr_en_delay1;
always_ff@(posedge clk_i or negedge rst_i) begin : reg_write_delay
  if(~rst_i)
    reg_wr_en_delay1  <= 0;
  else 
    reg_wr_en_delay1  <= reg_wr_en;
end

logic [31:0]mem_wr_data;

assign  mem_wr_data = buffer_output; //for now , maybe later it will change when i do other functions

assign reg_wr_data_o = dotp_out;
assign mem_wr_data_o = mem_wr_data;
//assign mem_wr_addr_o = mem_wr_addr;
assign mem_rd_en_o   = mem_rd_en;
assign mem_wr_en_o   = mem_wr_en;
assign reg_wr_en_o   = reg_wr_en_delay1;
assign ml_op_done_o  = ml_op_done;
assign ml_ready_o    = ml_ready;


endmodule
  




