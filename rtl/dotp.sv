


module dotp #(parameter XLEN = 32)(
input logic clk_half,
input logic rst_n,
input logic load, 
input logic enable,
input logic [XLEN-1:0] buf_a, 
input logic [XLEN-1:0] buf_b,
output logic [XLEN-1:0] out,
output logic ready
    );
    logic [XLEN-1:0] mult_a, mult_b, mult_out, add_a, add_b, add_out;
    
    
    //assign mult_a = (load)?(buf_a):(0);
    //assign mult_b = load?(buf_b):0;
    always_ff@(posedge clk_half or negedge rst_n) begin
     if(~rst_n) begin
      mult_a <= 0;
      mult_b <= 0;
     end
     else begin
      if(load) begin
       mult_a  <= buf_a;
       mult_b  <= buf_b;
      end
      else begin
       mult_a <= 0;
       mult_b <= 0;
      end
     end 
    end
         
    float_multiplier f_mult (
    .clk(clk_half), 
    .rst_n(rst_n),
    .irst(ready),
    .a(mult_a),
    .b(mult_b),
    .result(mult_out));
    
    logic [2:0] time_1;
    logic[2:0] time_2;
    logic[2:0] time_3;
    logic mux_sel;
    assign mux_sel = time_2[0] && time_2[1] && time_2[2];
    
    
  
    
   always_ff @ (posedge clk_half, negedge rst_n) begin 
     if(!rst_n)  time_1<= 0;
     else if(ready) time_1 <=0;
     else begin
       if(enable) begin
        if(~(load | time_1[2])) time_1<= time_1 + 1;
        else time_1 <= time_1;
       end
       else
        time_1 <=0;
     end
   end
   
   always_ff @ (posedge clk_half, negedge rst_n) begin 
     if(!rst_n)  time_2<= 0;
     else if(ready) time_2 <=0;
     else begin
       if(enable) begin
        if(time_1[2] && ~mux_sel) time_2<= time_2 + 1;
        else time_2 <= time_2;
       end
       else
        time_2 <= 0;
     end
   end  
   
 
   assign ready = time_3[2] && ~time_3[1] && ~time_3[0];
   
   always_ff @ (posedge clk_half, negedge rst_n) begin 
     if(!rst_n)  time_3<= 0;
     else if(ready) time_3 <=0;
     else begin
      if(enable) begin
        if(mux_sel && ~(time_3[2]&& time_3[0])) time_3<= time_3 + 1;
        else time_3 <= time_3;
      end
      else 
        time_3 <= 0;
     end
   end
   
   
    
    
    logic [31:0] buf_1, buf_2; 
    always_ff @ (posedge clk_half, negedge rst_n) begin 
    if(!rst_n) begin buf_1 <= 0; buf_2 <= 0; end
    else if(ready) begin buf_1 <= 0; buf_2 <= 0; end
    else begin buf_1 <= add_out;  buf_2<= buf_1; end   
    end
    
    
    
    assign add_a = add_out;
    assign add_b = (time_1[2])?(  mux_sel ? (buf_2):(buf_1) ):(mult_out);
    
    FloatingAddition #(XLEN) f_add (
    .clk(clk_half), 
    .rst_n(rst_n),
    .irst(ready),
    .A(add_a), 
    .B(add_b), 
    .result(add_out)
);  
   
    always_ff@(posedge clk_half or negedge rst_n) begin
     if(~rst_n)
      out <= 0;
     else begin
      if(enable) begin
       if(ready)
        out <= add_out;
       else
        out <= out;
      end
      else 
        out <= 0;
     end
    end 
    
      
    
endmodule
