

module count_manager (
    input  logic [31:0] size,             // 32-bit input size
    input  logic        clk,              // Clock signal
    input  logic        rst,              // Reset signal
    input  logic        load,
    input  logic        enable,
    output logic        last_one,         // signifies the last buffer output batch
    output logic [4:0]  count_to_buffer   // 5-bit output
);

    logic [31:0] remaining_size; // Remaining size to process
    
    logic        last;
    assign last_one = last;
    
    typedef enum logic [1:0] {
    RESET  = 2'b00,  
    LOAD   = 2'b01,  
    ENABLE = 2'b11 
} cm_state_t;
cm_state_t cm_cs,cm_ns;

    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            remaining_size  <= 0;
            count_to_buffer <= 0;
            last            <= 0;
        end 
        else begin
        if(cm_cs == LOAD) begin
           remaining_size  <= size;
           count_to_buffer <= 0;
           last            <= 0;
        end
        
        else if(cm_cs == ENABLE) begin
              if (remaining_size > 16) begin
                count_to_buffer <= 16;
                remaining_size  <= remaining_size - 16;
                last            <= 0;
              end 
              else begin
                count_to_buffer <= remaining_size[4:0]; // Take the remaining count
                remaining_size  <= 0;
                last            <= 1;
              end
        end
        else begin
           remaining_size  <= remaining_size;
           count_to_buffer <= count_to_buffer;
           last            <= last;
        end
      end
    end
    
    always_ff@(posedge clk or negedge rst) begin
      if(~rst)
      cm_cs <= RESET;
      else
      cm_cs <= cm_ns;
    end
    
    always_comb begin
       cm_ns = cm_cs;
       case(cm_cs)
       RESET: begin
        if(load) 
        cm_ns = LOAD;
        else if(enable)
        cm_ns = ENABLE;
        else
        cm_ns = RESET;
        end
       LOAD: begin
        if(enable)
        cm_ns = ENABLE;
        else
        cm_ns = LOAD;
        end
       ENABLE: begin
        cm_ns = RESET;
        end
        
       default : begin
        cm_ns = RESET;
        end
       endcase
    end


endmodule

