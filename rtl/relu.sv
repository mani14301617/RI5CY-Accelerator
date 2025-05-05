
module relu (
    input logic clk,
    input logic rst_n,
    input logic enable,
    input logic [31:0] float_value,
    output logic [31:0] relu_mapped_value

);


logic [31:0] temp,temp2;
assign temp = float_value;

assign temp2 = ~temp[31]?temp:32'h00000000;

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        relu_mapped_value <= 32'h00000000;
    end else if(enable) begin
        relu_mapped_value <= temp2;
    end
    else begin
       relu_mapped_value <= 0;
    end
end

endmodule
