// Copyright (c) 2024, Saligane's Group at University of Michigan and Google Research
//
// Licensed under the Apache License, Version 2.0 (the "License");

// you may not use this file except in compliance with the License.

// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module consmax_tb();

// Parameters
parameter FIXED_BIT = 8;
parameter EXP_BIT = 8;
parameter MAT_BIT = 7;
parameter LUT_DATA = EXP_BIT + MAT_BIT + 1;
parameter LUT_ADDR = FIXED_BIT >> 1;
parameter LUT_DEPTH = 2 ** LUT_ADDR;
parameter DATA_NUM_WIDTH = 10;
parameter SCALA_POS_WIDTH = 5;
parameter BUS_NUM = 8;
parameter DATA_NUM = 8;

// parameter for consmax computation
shortreal beta = 1;
shortreal gamma = 1;
shortreal cons = $exp(beta) / gamma; 

// Clock and reset
logic clk;
logic rst_n;

// Inputs
logic [DATA_NUM_WIDTH-1:0]              in_data_num;
logic                                   in_data_num_vld;
logic [BUS_NUM-1:0][FIXED_BIT-1:0]      in_fixed_data;
logic [BUS_NUM-1:0]                     in_fixed_data_vld;
logic signed [SCALA_POS_WIDTH-1:0]      in_scale_pos;
logic                                   in_scale_pos_vld;
logic signed [SCALA_POS_WIDTH-1:0]      out_scale_pos;
logic                                   out_scale_pos_vld;
logic [LUT_ADDR:0]                      lut_waddr;
logic                                   lut_wen;
logic [LUT_DATA-1:0]                    lut_wdata;

// Outputs
logic [BUS_NUM-1:0][FIXED_BIT-1:0]      out_fixed_data;
logic [BUS_NUM-1:0]                     out_fixed_data_vld;  
logic                                   out_fixed_data_last;

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz clock
end

// Reset generation
initial begin
    rst_n = 0;
    #20 rst_n = 1;
end

function shortreal bitsbfloat16_to_shortreal;
    input [15:0] x;
    begin
        logic [31:0] x_float;
        x_float = {x,16'b0};
        bitsbfloat16_to_shortreal = $bitstoshortreal(x_float);
    end
endfunction

function [15:0] shortreal_to_bitsbfloat16;
    input shortreal x;
    begin
        logic [31:0] x_float_bits;
        x_float_bits = $shortrealtobits(x);
        shortreal_to_bitsbfloat16 = x_float_bits[31:16] + x_float_bits[15];
    end
endfunction

//function  shortreal get_rand_shortreal();
//    shortreal min = -0.2;
//    shortreal max = 1;
//    get_rand_shortreal = min + (max-min)*(($urandom)*1.0/32'hffffffff);
//endfunction

// Reference Outputs
logic [BUS_NUM-1:0][FIXED_BIT-1:0]      out_fixed_data_ref;
shortreal                               out_float_data_ref_print [BUS_NUM-1:0];

task consmax_golden_data_gen ();
    /*
        since the system function in systemverilog does not support computation in bfloat16,
        the computation in this golden model is done in shortreal     
        (Might be an issue when comparing with the dut output)
    */
    // first convert the input fixed data to shortreal for computation
    shortreal real_data_array_in [DATA_NUM-1:0];
    shortreal real_data_array_out [DATA_NUM-1:0];
    int  int_data_array  [DATA_NUM-1:0];

    for (int i = 0; i < DATA_NUM; i++)begin
        real_data_array_in[i] = $itor($signed(in_fixed_data[i])) * $pow(2, $itor(-in_scale_pos));
    end

    // compute the results in short real
    for (int i = 0; i < DATA_NUM; i++)begin
        out_float_data_ref_print[i] = $exp(real_data_array_in[i] - beta) / gamma;
    end

    // convert the outputs back to fixed point number
    for (int i = 0; i < DATA_NUM; i++)begin
        int_data_array[i] = int'(out_float_data_ref_print[i]*$pow(2, $itor(out_scale_pos)));
        // deal with overflow
        if (int_data_array[i] > 127) 
            out_fixed_data_ref[i] = 127;
        else if (int_data_array[i] < -128)
            out_fixed_data_ref[i] = -128;
        else
            out_fixed_data_ref[i] = int_data_array[i]; 
    end

    $display("consmax output(float):");
    for (int i = 0; i < DATA_NUM; i++) begin
        $write("%.5f ", out_float_data_ref_print[i]);
    end
    
    $write("\n");

    $display("consmax output(fixpoint):");
    for (int i = 0; i < DATA_NUM; i++) begin
        $write("%8b ", out_fixed_data_ref[i]);
    end

endtask

task gen_rand_input_array();

    for (int i=0; i < DATA_NUM; i++) begin
        in_fixed_data[i] = $urandom & 8'hff;
    end

endtask

initial begin
    #30; // wait for reset
    // assign values to inputs
    in_scale_pos = 6;
    out_scale_pos = 2;
    gen_rand_input_array();

    #10;
    consmax_golden_data_gen();
    #100 $finish;
end

endmodule