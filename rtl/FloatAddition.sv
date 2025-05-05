

module FloatingAddition #(parameter XLEN=32) (
    input logic clk,
    input logic rst_n,
    input logic irst,
    input logic [XLEN-1:0] A,
    input logic [XLEN-1:0] B,
    output logic [XLEN-1:0] result
);



logic [23:0] Temp_Mantissa;
logic [22:0] Mantissa;
logic [7:0] Exponent;
logic Sign;

logic [32:0] Temp;
logic carry;
integer i;
/////////////////////////////////////////////////////
////////////         STAGE 1         ///////////////
/////////////////////////////////////////////////////
logic comp1, comp2;	   
logic [31:0] A1, A2, B1, B2;

assign A1 = A;
assign B1 = B; 

// Compare absolute values of A, B
FloatingCompare comp_abs (.A({1'b0, A1[30:0]}), .B({1'b0, B1[30:0]}), .result(comp1));

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        A2 <= 32'h0000_0000;
        B2 <= 32'h0000_0000;
        comp2 <= 0;
    end
     else if (irst) begin
        A2 <= 32'h0000_0000;
        B2 <= 32'h0000_0000;
        comp2 <= 0;
    end else begin
        A2 <= A1;
        B2 <= B1;
        comp2 <= comp1;
    end
end

/////////////////////////////////////////////////////
////////////         STAGE 2         ///////////////
/////////////////////////////////////////////////////

logic [31:0] A_swap, B_swap;
logic [23:0] A_Mantissa, B_Mantissa;
logic [7:0] A_Exponent, B_Exponent;
logic A_sign, B_sign;
logic [7:0] diff_Exponent;
logic [23:0] B_shifted_mantissa;

always_comb begin
    A_swap     = comp2 ? A2 : B2;
    B_swap     = comp2 ? B2 : A2;
    A_Mantissa = {1'b1, A_swap[22:0]};
    B_Mantissa = {1'b1, B_swap[22:0]};
    A_Exponent = A_swap[30:23];
    B_Exponent = B_swap[30:23];
    A_sign     = A_swap[31];
    B_sign     = B_swap[31];
    diff_Exponent      = A_Exponent - B_Exponent;
    B_shifted_mantissa = B_Mantissa >> diff_Exponent;
end

always_comb begin
    {carry, Temp_Mantissa} = (A_sign ~^ B_sign) ? A_Mantissa + B_shifted_mantissa : A_Mantissa - B_shifted_mantissa;
    Exponent = A_Exponent;
end


logic [23:0] Temp_Mantissa1;
logic carry1;
logic [7:0] Exponent1;
logic A_sign1;

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        Temp_Mantissa1 <= 24'h000000;
        Exponent1      <= 8'h00;
        carry1         <= 0;
        A_sign1        <= 0;
    end else if (irst) begin
        Temp_Mantissa1 <= 24'h000000;
        Exponent1      <= 8'h00;
        carry1         <= 0;
        A_sign1        <= 0;
    end else begin
        Temp_Mantissa1 <= Temp_Mantissa;
        Exponent1      <= Exponent;
        carry1         <= carry;
        A_sign1        <= A_sign;
    end
end

/////////////////////////////////////////////////////
////////////         STAGE 3         ///////////////
/////////////////////////////////////////////////////



logic [4:0] shift_amt;
logic [2:0] temp_shift_amt;
logic [1:0] lead_one_part;
logic zero;
logic [5:0]temp_subMantissa;
logic [23:0]Temp_Mantissa3o;

assign Temp_Mantissa3o = Temp_Mantissa1;

always_comb begin
   if(|Temp_Mantissa3o[23:18] == 1'b1) begin
     lead_one_part = 2'b00;
     zero = 1'b0;
     temp_subMantissa = Temp_Mantissa3o[23:18];
   end
   else if(|Temp_Mantissa3o[17:12] == 1'b1) begin
     lead_one_part = 2'b01;
     zero = 1'b0;
     temp_subMantissa = Temp_Mantissa3o[17:12];
   end
   else if(|Temp_Mantissa3o[11:6] == 1'b1) begin
     lead_one_part = 2'b10;
     zero = 1'b0;
     temp_subMantissa = Temp_Mantissa3o[11:6];
   end
   else if(|Temp_Mantissa3o[5:0] == 1'b1) begin
     lead_one_part = 2'b11;
     zero = 1'b0;
     temp_subMantissa = Temp_Mantissa3o[5:0];
   end
   else begin
     lead_one_part = 2'b00;
     zero = 1'b1;
     temp_subMantissa = 8'd0;
   end
end

always_comb begin
 casex(temp_subMantissa)
  6'b1xxxxx : temp_shift_amt = 3'b000;
  6'b01xxxx : temp_shift_amt = 3'b001;
  6'b001xxx : temp_shift_amt = 3'b010;
  6'b0001xx : temp_shift_amt = 3'b011;
  6'b00001x : temp_shift_amt = 3'b100;
  6'b000001 : temp_shift_amt = 3'b101;
  default :   temp_shift_amt = 3'b000;
 endcase
end




logic [2:0]temp_shift_amt1;
logic zero1;
logic [1:0]lead_one_part1;
logic carry2;
logic A_sign2;
logic [23:0] Temp_Mantissa2;
logic [7:0] Exponent2;

always_ff@(posedge clk or negedge rst_n) begin
   if(~rst_n) begin
     temp_shift_amt1 <= 0;
     zero1           <= 1;
     lead_one_part1  <= 0;
     carry2          <= 0;
     A_sign2         <= 0;
     Temp_Mantissa2  <= 0;
     Exponent2       <= 0;
   end
    else if(irst) begin
     temp_shift_amt1 <= 0;
     zero1           <= 1;
     lead_one_part1  <= 0;
     carry2          <= 0;
     A_sign2         <= 0;
     Temp_Mantissa2  <= 0;
     Exponent2       <= 0;
   end
   else begin
     temp_shift_amt1 <= temp_shift_amt;
     zero1           <= zero;
     lead_one_part1  <= lead_one_part;
     carry2          <= carry1;
     A_sign2         <= A_sign1;
     Temp_Mantissa2  <= Temp_Mantissa1;
     Exponent2       <= Exponent1;
   end 
end  

/////////////////////////////////////////////////////
////////////         STAGE 4         ///////////////
/////////////////////////////////////////////////////
logic [23:0]Temp_Mantissa31;
logic [23:0] Temp_Mantissa3;
logic [7:0] Exponent3,Exponent31;
logic [31:0]temp_result;
//quant computes the lead_zero_part*6 
logic [4:0] quant;

assign quant = {lead_one_part1[0]&lead_one_part1[1],~lead_one_part1[0]&lead_one_part1[1],lead_one_part1[0]^lead_one_part1[1],lead_one_part1[0],1'b0};
assign shift_amt = quant + {2'b00,temp_shift_amt1};
assign Temp_Mantissa31 = Temp_Mantissa2;
assign Exponent31 = Exponent2;

always_comb begin
    if (carry2) begin
        Temp_Mantissa3 = {1'b1,Temp_Mantissa31[23:1]};
        Exponent3      = (Exponent31 < 8'hFF) ? Exponent31 + 1 : 8'hFF;
    end 
    else if (zero1) begin
        Temp_Mantissa3 = 0;
        Exponent3 = 0;
    end 
    else begin
        Temp_Mantissa3 = Temp_Mantissa31 << shift_amt;
        Exponent3      = Exponent31 - {3'b000,shift_amt};
    end
    Sign = A_sign2;
    Mantissa = Temp_Mantissa3[22:0];
    temp_result = {Sign, Exponent3, Mantissa};
end

always_ff@(posedge clk or negedge rst_n) begin
  if(~rst_n)
   result <= 0;
  else if(irst)
   result <= 0;
  else
   result <= temp_result;
end
endmodule
