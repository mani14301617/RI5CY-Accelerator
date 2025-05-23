// Copyright 2018 Robert Balas <balasr@student.ethz.ch>
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Top level wrapper for a verilator RI5CY testbench
// Contributor: Robert Balas <balasr@student.ethz.ch>

module tb_top_verilator
    #(parameter INSTR_RDATA_WIDTH = 128,
      parameter RAM_ADDR_WIDTH = 22,
      parameter BOOT_ADDR  = 'h80)
    (input logic clk_i,
     input logic  rst_ni,
     input logic  fetch_enable_i,
     output logic tests_passed_o,
     output logic tests_failed_o);

    // cycle counter
    int unsigned            cycle_cnt_q;

    // testbench result
    logic                   exit_valid;
    logic [31:0]            exit_value;


    // we either load the provided firmware or execute a small test program that
    // doesn't do more than an infinite loop with some I/O
    initial begin: load_prog
        automatic logic [1023:0] firmware;
        automatic int prog_size = 6;

        if($value$plusargs("firmware=%s", firmware)) begin
            if($test$plusargs("verbose"))
                $display("[TESTBENCH] %t: loading firmware %0s ...",
                         $time, firmware);
            $readmemh(firmware, cv32e40p_tb_wrapper_i.ram_i.dp_ram_i.mem);
            //for (int i = 0; i < 16; i++) begin                                          //custom
            //$display("Memory[%0d]: %h", i, cv32e40p_tb_wrapper_i.ram_i.dp_ram_i.mem[i]);//custom
        //end                                                                             //custom
        end else begin
            $display("No firmware specified");
            $finish;
        end
     end

    // abort after n cycles, if we want to
    always_ff @(posedge clk_i, negedge rst_ni) begin
        automatic int maxcycles;
        if($value$plusargs("maxcycles=%d", maxcycles)) begin
            if (~rst_ni) begin
                cycle_cnt_q <= 0;
            end else begin
                cycle_cnt_q     <= cycle_cnt_q + 1;
                if (cycle_cnt_q >= maxcycles) begin
                    // we $finish instead of $fatal because riscv-compliance
                    // interprets the return error code as total failure, which
                    // we don't want
                    $finish("Simulation aborted due to maximum cycle limit");
                end
            end
        end
    end

    // check if we succeded
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (tests_passed_o) begin
            $display("%m @ %0t: ALL TESTS PASSED", $time);
            $finish;
        end
        if (tests_failed_o) begin
            $display("%m @ %0t: TEST(S) FAILED!", $time);
            $finish;
        end
        if (exit_valid) begin
            if (exit_value == 0)
                $display("%m @ %0t: EXIT SUCCESS", $time);
            else
                $display("%m @ %0t: EXIT FAILURE: %d", exit_value, $time);
            $finish;
        end
    end
    
///////////////////////////////// CUSTOM CHECKING  /////////////////////////    
//  int clock_count;
//initial begin
//    clock_count = 0;
//end

//always_ff @(posedge clk_i) begin
 //   if (clock_count < 20) begin
  //      clock_count <= clock_count + 1;
  //      $display("Clock count: %0d, rst_ni: %0b", clock_count, rst_ni);
        
  //  end else begin
 //       $display("Reached maximum clock count of 10.");
 //       $finish;
 //   end
//end

//always_ff @(posedge clk_i) begin
//    if (!rst_ni) begin
//        $display("Resetting...");
//    end else if (fetch_enable_i) begin
//        $display("PC:");
//    end
//end


////////////////////////////////////////////////////////////////

    // wrapper for cv32e40p, the memory system and stdout peripheral
    cv32e40p_tb_wrapper
        #(.INSTR_RDATA_WIDTH (INSTR_RDATA_WIDTH),
          .RAM_ADDR_WIDTH    (RAM_ADDR_WIDTH),
          .BOOT_ADDR         (BOOT_ADDR),
          .PULP_CLUSTER      (0),
          .FPU               (0),
          .PULP_ZFINX        (0),
          .DM_HALTADDRESS    (32'h1A110800)
         )
    cv32e40p_tb_wrapper_i
        (.clk_i          ( clk_i          ),
         .rst_ni         ( rst_ni         ),
         .fetch_enable_i ( fetch_enable_i ),
         .tests_passed_o ( tests_passed_o ),
         .tests_failed_o ( tests_failed_o ),
         .exit_valid_o   ( exit_valid     ),
         .exit_value_o   ( exit_value     ));

endmodule // tb_top_verilator
