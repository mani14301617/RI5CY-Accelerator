

module float_multiplier(
    input  logic  clk,
    input  logic rst_n,
    input  logic irst,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result
);



//STAGE 1
logic [31:0]A1,B1;
logic sign, exception, zero;
logic[8:0] sum_exponent;
logic [23:0] op_a, op_b;

//always_ff@(posedge clk or negedge rst_n) begin
// if(~rst_n) begin
// A1<=0;
// B1<=0;
// end 
// else begin
 /*A1<=a;
 B1<=b;
 end 
end*/

assign A1 = a;
assign B1 = b;

always_comb begin
 sign = A1[31] ^ B1[31];  // XOR of 32nd bit
 exception = (&A1[30:23]) | (&B1[30:23]);// Exception sets to 1 when exponent of any a or b is 255
zero = exception ? 1'b0 : ( ~|A1[30:0] | ~|B1[30:0] ); 
 sum_exponent = A1[30:23] + B1[30:23];
 op_a = (|A1[30:23]) ? {1'b1, A1[22:0]} : {1'b0, A1[22:0]};
 op_b = (|B1[30:23]) ? {1'b1, B1[22:0]} : {1'b0, B1[22:0]};
end

//STAGE 2


logic [23:0]op_A1,op_B1;
logic sign1;
logic exception1;
logic [8:0]sum_exponent1;
logic zero1;
logic [47:0] product, product_normalised;
logic normalised;

always_ff@(posedge clk or negedge rst_n) begin
 if(~rst_n) begin
 sign1<=0;
 op_A1<=0;
 op_B1<=0;
 exception1<=0;
 sum_exponent1<=0;
 zero1<=0;
 end 
 else if(irst) begin
 sign1<=0;
 op_A1<=0;
 op_B1<=0;
 exception1<=0;
 sum_exponent1<=0;
 zero1<=0;
 end
 else begin
 sign1<=sign;
 op_A1<=op_a;
 op_B1<=op_b;
 exception1<=exception;
 sum_exponent1<=sum_exponent;
 zero1<=zero;
 end 
end

always_comb begin
 product = op_A1 * op_B1;													// Product
// round = |product_normalised[22:0];  											// Last 22 bits are ORed for rounding off purpose
 normalised = product[47];	
 product_normalised = normalised ? product : product << 1;
end


//STAGE 3

logic [47:0]product_normalised1;
logic exception2;
logic [8:0]sum_exponent2;
logic normalised1;
logic sign2;
logic zero2;
logic [8:0] exponent;
logic [22:0] product_mantissa;
logic underflow, overflow;
logic [31:0]res;


always_ff@(posedge clk or negedge rst_n) begin
 if(~rst_n) begin
 product_normalised1 <= 0;
 normalised1 <= 0;
 sum_exponent2<=0;
 exception2<=0;
 sign2<=0;
 zero2<=0;
 end 
 else if(irst) begin
 product_normalised1 <= 0;
 normalised1 <= 0;
 sum_exponent2<=0;
 exception2<=0;
 sign2<=0;
 zero2<=0;
 end 
 else begin
 product_normalised1 <= product_normalised;
 normalised1 <= normalised;
 sum_exponent2<=sum_exponent1;
 exception2<=exception1;
 sign2<=sign1;
 zero2<=zero1;
 end 
end		

always_comb begin
 product_mantissa = product_normalised1[46:24] + (product_normalised1[23]);// & round); //Mantissa
 exponent = sum_exponent2 - 8'd127 + normalised1;
 overflow = ((exponent[8] & !exponent[7]) & !zero2); 									// Overall exponent is greater than 255 then Overflow
 underflow = ((exponent[8] & exponent[7]) & !zero2); 										// Sum of exponents is less than 255 then Underflow
 res = exception2 ? 32'h7F800000 : 
             zero2 ? {sign2, 31'd0} : 
             overflow ? {sign2, 8'hFF, 23'd0} : 
             underflow ? {sign2, 31'd0} : 
             {sign2, exponent[7:0], product_mantissa};
end


//STAGE 4

always_ff@(posedge clk or negedge rst_n) begin
 if(~rst_n) begin
 result <=0;
 end 
 else if(irst) begin
 result <=0;
 end 
 else begin
 result <=res;
 end 
end


endmodule
