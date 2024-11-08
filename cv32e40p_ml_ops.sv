import cv32e40p_pkg::*;
// Don't touch this code

module cv32e40p_ml_ops(
    input  logic        ml_ops_enable_i,
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [31:0] mem_rdata_i,
    input  logic [31:0] operand_a_addr_i,
    input  logic [31:0] operand_b_size_i,
    input  logic        loading_data_i,
    output logic        load_data,
    output logic        ml_op_done_o,
    output logic        ml_ready_o,
    input  ml_opcode_e  ml_oper_i,
    output logic [31:0] cal_value_o, //  sigmoid, relu, softmax, or the dot product
    output logic        reg_or_mem_o, // the data goes to memory(1) or register file(0)
    output logic [31:0] data_addr_o,
    output logic        wr_en_o,  // write enable, (either trying to write into reg or mem)
    output logic        mem_data_req_o,
    input  logic        ml_dotp_en_i,           //
    input  logic        ml_relu_en_i,          //
    input  logic        ml_sigmoid_en_i,      //
    input  logic        ml_softmax_en_i,       //
    input  logic        ml_matrixmult_en_i,    //everything will come in signed mode only
    input  logic        ml_matrixadd_en_i,
    input  logic        ex_ready_i
);

logic ml_dotp_en;
logic ml_ops_enable;
logic [31:0] size [0:1];
logic [31:0] addr [0:1];
logic [31:0] temp_size;
logic [31:0] temp_addr;
logic operand1_stored, operand2_stored;
logic temp;
logic [1:0] load_count;
logic get_over_idle;
logic [31:0] ML_RF1 [0:15]; // register file for first vector
logic [31:0] ML_RF2 [0:15]; // register file for second vector

parameter load1_lim = 16;
parameter load2_lim = 16;


logic [31:0] data_count1, data_count2;
logic [31:0] data_addr1, data_addr2;
logic [4:0] rf_size_count1, rf_size_count2;
logic rf_batch;
logic data_req;
logic complete_load1, complete_load2;
logic rf1_full, rf2_full;
logic go_to_load2, go_to_comp;
logic comp;
logic signed [31:0] comp_regs [0:3];
logic signed [31:0] final_result;

logic partial_comp_done, complete_comp_done;

logic dotp_done;
assign loading_data = loading_data_i;
assign ml_dotp_en   = ml_dotp_en_i;
assign ml_ops_enable = ml_ops_enable_i;
typedef enum logic [2:0] {
    RESET = 3'b000,  // just reset state
    IDLE  = 3'b001,  // waits for the sizes and addr to be stored
    IDLE1 = 3'b010,  // latency of one so that my dotp instruction can be read
    LOAD1 = 3'b011,  // loading the data of the first operand
    LOAD2 = 3'b100,  // loading the data of the second operand
    IDLE2 = 3'b101,  // due to the latency of 1 while loading , placing an idle state to compensate
    COMP  = 3'b110,  // computation
    END   = 3'b111   // process done
} dotp_state_t;

dotp_state_t dotp_cs, dotp_ns;

always_ff @(posedge clk_i or negedge rst_i) begin : a // loading the size and address
    if (~rst_i) begin
        size[0] <= 0; size[1] <= 0;
        addr[0] <= 0; addr[1] <= 0;
        load_count <= 0;
    end else begin
    if(ml_ops_enable) begin
        if (loading_data) begin
            size[load_count] <= operand_b_size_i;
            addr[load_count] <= operand_a_addr_i;
            load_count <= load_count + 1;
        end else if (load_count == 2'b10) begin
            load_count <= 0;
            end
            else begin
            size[load_count] <= size[load_count];
            addr[load_count] <= addr[load_count];
            end
            
        end
    end
end


always_ff @(posedge clk_i or negedge rst_i) begin : b// loading the register file 1
    if (~rst_i || ((dotp_cs == IDLE1) & ml_dotp_en)) begin
        for (int i = 0; i < 16; i++) begin
            ML_RF1[i] <= 0;
        end
    end else if ((dotp_cs == LOAD1) & ml_dotp_en) begin
        ML_RF1[rf_size_count1] <= mem_rdata_i;
    end
end

always_ff @(posedge clk_i or negedge rst_i) begin : c// loading the register file 2
    if (~rst_i || ((dotp_cs == IDLE1)&ml_dotp_en)) begin
        for (int i = 0; i < 16; i++) begin
            ML_RF2[i] <= 0;
        end
    end else if ((dotp_cs == LOAD2) & ml_dotp_en) begin
        if (data_count2 < size[0]) begin
            ML_RF2[rf_size_count2] <= mem_rdata_i;
        end
    end
end
logic data_count_delay1,data_count_delay2;

always_ff @(posedge clk_i or negedge rst_i) begin : de // since the memory which we get has a latency of one  , in order to stop missing out on filling the 0th registers , 
                                                      // introduce a delay in ((dotp_cs == LOADx)&ml_ops_enable) 
    if(~rst_i) begin data_count_delay1 <= 0; data_count_delay2 <= 0; end
    else begin data_count_delay1 <= (dotp_cs == LOAD1) & ml_ops_enable; data_count_delay2 <= (dotp_cs == LOAD2) & ml_ops_enable; end
end

always_ff @(posedge clk_i or negedge rst_i) begin : d1
if(~rst_i) data_addr1 <=0 ;
else if(load_count == 2'b10 && ml_ops_enable) data_addr1 <= addr[0];
else if((dotp_cs == LOAD1) & ml_ops_enable)  begin
       if ((rf_size_count1 < (load1_lim - 1))  && ml_ops_enable) 
            data_addr1 <= data_addr1 + 4;
       else if ((rf_size_count1 == (load1_lim - 1))  && ml_ops_enable) data_addr1 <= data_addr1;
     end
end

always_ff @(posedge clk_i or negedge rst_i) begin : d// update the data fetching address and assigning position for data 1
    if (~rst_i) begin
        data_count1 <= 0;
        rf_size_count1 <= 0;
    end else if (load_count == 2'b10 && ml_ops_enable) begin
        data_count1 <= 0;
        rf_size_count1 <= 0;
    end else if (data_count_delay1) begin
        if (data_count1 < size[0] && rf_size_count1 < load1_lim) begin
            data_count1 <= data_count1 + 1;
            rf_size_count1 <= rf_size_count1 + 1;
        end if ((rf_size_count1 == (load1_lim))  && ml_ops_enable) begin
            rf_size_count1 <= 0;
        end
    end
end

always_ff @(posedge clk_i or negedge rst_i) begin : e1
if(~rst_i) data_addr2 <=0 ;
else if(load_count == 2'b10 && ml_ops_enable) data_addr2 <= addr[1];
else if((dotp_cs == LOAD2) & ml_ops_enable)  begin
       if ((rf_size_count2 < (load2_lim - 1))  && ml_ops_enable) 
            data_addr2 <= data_addr2 + 4;
       else if ((rf_size_count2 == (load2_lim - 1))  && ml_ops_enable) data_addr2 <= data_addr2;
     end
end

always_ff @(posedge clk_i or negedge rst_i) begin : e // update the data fetching address and assigning position for data 2
    if (~rst_i) begin
        data_count2 <= 0;
        rf_size_count2 <= 0;
    end else if (load_count == 2'b10 && ml_ops_enable) begin
        data_count2 <= 0;
        rf_size_count2 <= 0;
    end else if (data_count_delay2) begin
        if (data_count2 < size[1] && rf_size_count2 < load2_lim) begin
            data_count2 <= data_count2 + 1;
            rf_size_count2 <= rf_size_count2 + 1;
        end  if ((rf_size_count2 == (load2_lim)) && ml_ops_enable) begin
            rf_size_count2 <= 0;
        end
    end
end

always_comb begin : f 
    complete_load1 = (data_count1 == (size[0]-1));
    complete_load2 = (data_count2 == (size[1]-1));
    rf1_full = (rf_size_count1 == (load1_lim-1));
    rf2_full = (rf_size_count2 == (load2_lim-1));
end

assign go_to_load2 = (complete_load1 || rf1_full);
assign go_to_comp = (complete_load2 || rf2_full);

always_ff @(posedge clk_i or negedge rst_i) begin : g// updating the current state
    if (~rst_i) begin
        dotp_cs <= RESET;
    end else begin
        if(ml_ops_enable) begin
            
           dotp_cs <= dotp_ns;
           
        end
        
   end
end

always_comb begin : h
    comp_regs[0] = $signed(ML_RF1[0]) * $signed(ML_RF2[0]) + $signed(ML_RF1[1]) * $signed(ML_RF2[1]) + $signed(ML_RF1[2]) * $signed(ML_RF2[2]) + $signed(ML_RF1[3]) * $signed(ML_RF2[3]);
    comp_regs[1] = $signed(ML_RF1[4]) * $signed(ML_RF2[4]) + $signed(ML_RF1[5]) * $signed(ML_RF2[5]) + $signed(ML_RF1[6]) * $signed(ML_RF2[6]) + $signed(ML_RF1[7]) * $signed(ML_RF2[7]);
    comp_regs[2] = $signed(ML_RF1[8]) * $signed(ML_RF2[8]) + $signed(ML_RF1[9]) * $signed(ML_RF2[9]) + $signed(ML_RF1[10]) * $signed(ML_RF2[10]) + $signed(ML_RF1[11]) * $signed(ML_RF2[11]);
    comp_regs[3] = $signed(ML_RF1[12]) * $signed(ML_RF2[12]) + $signed(ML_RF1[13]) * $signed(ML_RF2[13]) + $signed(ML_RF1[14]) * $signed(ML_RF2[14]) + $signed(ML_RF1[15]) * $signed(ML_RF2[15]);
end

always_ff @(posedge clk_i or negedge rst_i) begin : i
    if (~rst_i) begin
        final_result <= 0;
        partial_comp_done <= 0;
    end else if (dotp_cs == COMP && ml_ops_enable && ml_dotp_en) begin
        final_result <= $signed(final_result) + $signed(comp_regs[0]) + $signed(comp_regs[1]) + $signed(comp_regs[2]) + $signed(comp_regs[3]);
        partial_comp_done <= 1;
    end
    else if(dotp_cs == IDLE) begin final_result <= 0; partial_comp_done <=0; end
end

//assign complete_comp_done = complete_load2 & partial_comp_done;
always_ff@(posedge clk_i , negedge rst_i) begin
   if( ~rst_i ) 
       complete_comp_done <=0 ;
   else begin 
       if(complete_load2 & partial_comp_done) complete_comp_done <= 1;
       else if(ml_op_done_o) complete_comp_done <= 0;
       else complete_comp_done <= complete_comp_done;
   end
end


always_comb begin  : j // updating the next state 
    dotp_ns = dotp_cs;
    dotp_done = 1'b0;
    if(ml_ops_enable) begin
    case (dotp_cs)
        RESET: begin
            data_req = 0;
            load_data = 1'b0;
            dotp_done = 0;
            comp = 0;
            if (loading_data)
                dotp_ns = IDLE;
        end

        IDLE: begin
            data_req = 0;
            load_data = 1'b0;
            dotp_done = 0;
            
                dotp_ns = IDLE1;
        end
        IDLE1: begin
          if (~loading_data && ml_dotp_en)
                dotp_ns = LOAD1; end
                
        LOAD1: begin
            data_req = 1;
            dotp_done = 0;
            load_data = 1;
            if (go_to_load2)
                dotp_ns = LOAD2;
        end

        LOAD2: begin
            data_req = 1;
            dotp_done = 0;
            load_data = 1;
            if (go_to_comp)
                dotp_ns = IDLE2;
        end
        
        IDLE2: begin
         dotp_ns = COMP;
         end
         
        COMP: begin
        data_req = 0;
            dotp_done = 0;
            load_data = 0;
            comp = 1;
            if (complete_comp_done)
                dotp_ns = END;
            else dotp_ns = IDLE1;
        end

        END: begin
            data_req = 0;
            dotp_done = 1;
            comp =0 ;
            if(ex_ready_i) dotp_ns = RESET;
        end

        default: begin
            data_req = 0;
            dotp_ns = RESET;
            dotp_done = 0;
        end
    endcase
  end
end

assign data_addr_o = (dotp_cs == LOAD1) ? data_addr1 : data_addr2;
assign cal_value_o = final_result;
assign reg_or_mem_o = 0;
assign wr_en_o = dotp_done ;
assign ml_op_done_o = dotp_done ;
assign ml_ready_o = ( ~ml_ops_enable | loading_data | ml_op_done_o | ((dotp_cs==IDLE1)&(~comp)));
assign mem_data_req_o = data_req;
endmodule

