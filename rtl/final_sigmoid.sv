


module sigmoid_map #(
    parameter int DATA_WIDTH = 32  // Width of each register
)(
    input  logic [4:0] select_addr,  // Address input
    input  logic [3:0] reg_select,
    output logic [DATA_WIDTH-1:0] rd_data // Data read output
);

logic [1:0] m4, p2;
logic m5;
logic [2:0] m3;
logic [3:0] m2, m1, p1;
logic [4:0] m0;

assign m4 = select_addr[1:0];
assign p2 = select_addr[1:0];
assign m5 = select_addr[0];
assign m3 = select_addr[2:0];
assign m2 = select_addr[3:0];
assign m1 = select_addr[3:0];
assign p1 = select_addr[3:0];
assign m0 = select_addr[4:0];

// Read-only memory (ROM) initialized with values
const logic [DATA_WIDTH-1:0] reg_mem_m8 = 32'h3F00638E;
const logic [DATA_WIDTH-1:0] reg_mem_m7 = 32'h3F00C71C;
const logic [DATA_WIDTH-1:0] reg_mem_m6 = 32'h3F018E33;

const logic [DATA_WIDTH-1:0] reg_mem_m5 [0:1] = {
    32'h3F028872,
    32'h3F0385DD
};

const logic [DATA_WIDTH-1:0] reg_mem_m4 [0:3] = {
    32'h3F048441,
    32'h3F058300,
    32'h3F0681D6,
    32'h3F0780A1
};

const logic [DATA_WIDTH-1:0] reg_mem_m3 [0:7] = {
    32'h3F087F4B,
    32'h3F097DC4,
    32'h3F0A7BFE,
    32'h3F0B79EE,
    32'h3F0C778A,
    32'h3F0D74CA,
    32'h3F0E71A3,
    32'h3F0F6E0E
};

const logic [DATA_WIDTH-1:0] reg_mem_m2 [0:15] = {
    32'h3F106A02,
    32'h3F116578,
    32'h3F126067,
    32'h3F135AC8,
    32'h3F145493,
    32'h3F154DC1,
    32'h3F16464A,
    32'h3F173E28,
    32'h3F183552,
    32'h3F192BC3,
    32'h3F1A2172,
    32'h3F1B165A,
    32'h3F1C0A74,
    32'h3F1CFDB9,
    32'h3F1DF022,
    32'h3F1EE1A8
};

const logic [DATA_WIDTH-1:0] reg_mem_m1 [0:15] = {
    32'h3F204BF0,
    32'h3F222946,
    32'h3F2402AA,
    32'h3F25D7EC,
    32'h3F27A8E0,
    32'h3F29755C,
    32'h3F2B3D38,
    32'h3F2D004B,
    32'h3F2EBE73,
    32'h3F30778D,
    32'h3F322B77,
    32'h3F33DA15,
    32'h3F358349,
    32'h3F3726F9,
    32'h3F38C50D,
    32'h3F3A5D6E
};

const logic [DATA_WIDTH-1:0] reg_mem_m0 [0:31] = {
    32'h3F3BF00A,
    32'h3F3D7CCD,
    32'h3F3F03A7,
    32'h3F40848B,
    32'h3F41FF6B,
    32'h3F43743D,
    32'h3F44E2FA,
    32'h3F464B98,
    32'h3F47AE15,
    32'h3F490A6C,
    32'h3F4A609A,
    32'h3F4BB0A1,
    32'h3F4CFA82,
    32'h3F4E3E3E,
    32'h3F4F7BDB,
    32'h3F50B35D,
    32'h3F51E4CC,
    32'h3F53102F,
    32'h3F543590,
    32'h3F5554F9,
    32'h3F566E76,
    32'h3F578211,
    32'h3F588FDA,
    32'h3F5997DD,
    32'h3F5A9A2B,
    32'h3F5B96D2,
    32'h3F5C8DE3,
    32'h3F5D7F6F,
    32'h3F5E6B87,
    32'h3F5F523F,
    32'h3F6033A8,
    32'h3F610FD5
};

const logic [DATA_WIDTH-1:0] reg_mem_p1 [0:15] = {
    32'h3F6320AD,
    32'h3F662D45,
    32'h3F68EFD3,
    32'h3F6B6DA2,
    32'h3F6DABFC,
    32'h3F6FB00C,
    32'h3F717ED4,
    32'h3F731D16,
    32'h3F748F53,
    32'h3F75D9C1,
    32'h3F770047,
    32'h3F780680,
    32'h3F78EFBB,
    32'h3F79BEFE,
    32'h3F7A7707,
    32'h3F7B1A53
};
const logic [DATA_WIDTH-1:0] reg_mem_p2 [0:3] = {
    32'h3F7D201F,
    32'h3F7EEE46,
    32'h3F7F9AC7,
    32'h3F7FDAA9
    };
    
always_comb begin
    case(reg_select)
        4'b0000: rd_data = reg_mem_m8;
        4'b0001: rd_data = reg_mem_m7;
        4'b0010: rd_data = reg_mem_m6;
        4'b0011: rd_data = reg_mem_m5[m5];
        4'b0100: rd_data = reg_mem_m4[m4];
        4'b0101: rd_data = reg_mem_m3[m3];
        4'b0110: rd_data = reg_mem_m2[m2];
        4'b0111: rd_data = reg_mem_m1[m1];
        4'b1000: rd_data = reg_mem_m0[m0];
        4'b1001: rd_data = reg_mem_p1[p1];
        4'b1010: rd_data = reg_mem_p2[p2];
        default: rd_data = 32'b0;
    endcase
end

endmodule





module one_minus_x #(parameter XLEN = 32) (
    input  logic [XLEN-1:0] A,
    output logic [XLEN-1:0] result
);

    logic [7:0] exp;
    logic [23:0] temp_mantissa1, temp_mantissa2;
    logic [7:0] one_expo;
    const logic [23:0] one_mantissa = 24'h800000;
    integer i;
    
    assign temp_mantissa1 = {2'b01, A[22:1]};
    
    logic [22:0] Mantissa;
    logic [7:0] Exponent; 
    
    always_comb begin
        temp_mantissa2 = one_mantissa - temp_mantissa1;
        one_expo = 8'b0111_1111;

        for (i = 0; temp_mantissa2[23] !== 1'b1 && i < 24; i++) begin
            temp_mantissa2 = temp_mantissa2 << 1;
            one_expo = one_expo - 1;
        end

        Mantissa = temp_mantissa2[22:0];
        Exponent = one_expo;
        result = {1'b0, Exponent, Mantissa};
    end

endmodule




module sigmoid (
    input logic clk,
    input logic rst_n,
    input logic enable,
    input logic [31:0] float_value,
    output logic [31:0] sig_mapped_value

);

logic temp_sign;
logic [7:0] temp_exp;
logic [22:0] temp_frac;
logic low_end;
logic high_end;

logic [31:0] temp_value,  temp2_value;

assign temp_sign = temp_value[31];
assign temp_exp  = temp_value[30:23];
assign temp_frac = temp_value[22:0];

assign low_end  = (temp_exp < 119);
assign high_end = (temp_exp > 129);

logic [31:0] mapping_addr;

assign temp_value = float_value;

logic [3:0] reg_select;
logic [4:0] select_addr;
logic [31:0] sig_data;
logic [31:0] adder_out;



sigmoid_map sm(.select_addr(select_addr), .reg_select(reg_select), .rd_data(sig_data));


one_minus_x omx(.A(sig_data), .result(adder_out));

always_comb begin
    if (low_end) begin
        temp2_value = 32'h3F000000;
    end else if (high_end) begin
        if (temp_sign)
            temp2_value = 32'h00000000;
        else
            temp2_value = 32'h3F800000;
    end else begin
        case (temp_exp)
            8'b01110111: begin  reg_select = 4'b0000; select_addr = 5'b00000;  end                // m8
            8'b01111000: begin reg_select = 4'b0001; select_addr = 5'b00000;   end               // m7
            8'b01111001: begin reg_select = 4'b0010; select_addr = 5'b00000;   end               // m6
            8'b01111010: begin reg_select = 4'b0011; select_addr = {4'b0000, temp_frac[22]}; end  // m5
            8'b01111011: begin reg_select = 4'b0100; select_addr = {3'b000, temp_frac[22:21]}; end // m4
            8'b01111100: begin reg_select = 4'b0101; select_addr = {2'b00, temp_frac[22:20]}; end // m3
            8'b01111101: begin reg_select = 4'b0110; select_addr = {1'b0, temp_frac[22:19]}; end   // m2
            8'b01111110: begin reg_select = 4'b0111; select_addr = {1'b0, temp_frac[22:19]};  end // m1
            8'b01111111: begin reg_select = 4'b1000; select_addr = temp_frac[22:18];    end      // m0
            8'b10000000: begin reg_select = 4'b1001; select_addr = {1'b0, temp_frac[22:19]}; end  // p1
            8'b10000001: begin reg_select = 4'b1010; select_addr = {3'b000, temp_frac[22:21]}; end // p2
            default:     begin reg_select = 4'b1111; select_addr = 5'b00000; end
        endcase
        
        if (temp_sign)
            temp2_value = adder_out;
        else
            temp2_value = sig_data;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sig_mapped_value <= 32'h00000000;
    end else if(enable) begin
        sig_mapped_value <= temp2_value;
    end
    else begin
       sig_mapped_value <= 0;
    end
end

endmodule
