


// Returns A >= B via the output logic signal
module FloatingCompare (
    input logic [31:0] A,
    input logic [31:0] B,
    output logic result
);
logic temp;
always_comb begin
    // Compare signs
    if (A[31] != B[31]) begin
        result = ~A[31];  // A is positive (0) -> A >= B -> result = 1
        temp   = 0;
        end
    // Compare exponents
    else if (A[30:23] != B[30:23]) begin
        temp = (A[30:23] > B[30:23]) ? 1'b1 : 1'b0;  // A has bigger exponent than B
        if (A[31]) result = ~temp; 
        else result = temp; // If A is negative, bigger exponent means smaller number
    end
    // Compare mantissas
    else begin
        temp = (A[22:0] > B[22:0]) ? 1'b1 : 1'b0;  // A has bigger mantissa than B
        if (A[31]) result = ~temp; 
        else result = temp; // If A is negative, bigger mantissa means smaller number
    end
end

endmodule

