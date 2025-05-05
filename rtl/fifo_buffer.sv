


module fifo (
    input  logic                 clk,
    input  logic                 rst_n,      // Active-low reset (from another module)
    input  logic [4:0]           count_ext,
    input  logic                 push,       // Push data into FIFO
    input  logic                 pop,        // Pop data from FIFO (controlled internally)
    input  logic [31:0]          din,        // Data input
    input  logic                 enable,     // Enable input
    output logic [31:0]          dout,       // Data output to memory
    output logic                 full,       // FIFO full flag
    output logic                 empty      // FIFO empty flag
 
);

    // Internal storage
    logic [31:0] mem [0:15];  // FIFO memory array
    logic [4:0] rd_ptr, wr_ptr;  // Read/write pointers
    logic [4:0] count;           // Number of stored elements
    logic empty_delay1;
    logic full_delay1;
    // FIFO Write (Push)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end 
        else if(enable) begin
          if (push && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
           end
          else if(empty_delay1) begin
            wr_ptr <= 0;
           end
        end
    end

    // FIFO Read (Pop) - Controlled by write_enable (only read when FIFO is full)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            dout <= 0;
        end 
        else if(enable) begin
          if (pop && !empty) begin
            dout <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
          end
          else if(full) begin
            rd_ptr <= 0;
          end
        end
    end

    // FIFO Count Management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end 
        else if(enable) begin
          if (push && !full) begin
            count <= count + 1;
          end 
          else if (pop && !empty) begin
            count <= count - 1;
          end
        end
    end
   always_ff@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        empty_delay1 <= 0;
        full_delay1  <= 0;
      end
      else begin
        empty_delay1 <= empty;
        full_delay1  <= full;
      end
   end
   
    // Control Signals
    assign full  = (count == count_ext) ;   // FIFO is full
    assign empty = (count == 0);       // FIFO is empty
    

endmodule

