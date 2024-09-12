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

// =============================================================================
// ConSmax Top Module_

module consmax #(
    parameter   FIXED_BIT = 8,  // Fixed point width

    parameter   EXP_BIT = 8,    // Exponent
    parameter   MAT_BIT = 7,    // Mantissa
    parameter   LUT_DATA  = EXP_BIT + MAT_BIT + 1,  // LUT Data Width (in FP)
    parameter   LUT_ADDR  = IDATA_BIT >> 1,         // LUT Address Width
    parameter   LUT_DEPTH = 2 ** LUT_ADDR,           // LUT Depth for INT2FP

    parameter integer DATA_NUM_WIDTH =  10, // vector length reg width
    parameter integer SCALA_POS_WIDTH = 5,  // fixed point scale position width
    parameter integer BUS_NUM = 8,          //input bus num

    localparam        isize = 8,
    localparam        isign = 1, //signed integer number
    localparam        ieee_compliance = 0 //No support to NaN adn denormals
)
(
    // Global Signals
    input   logic                                               clk,
    input   logic                                               rst_n,
    
    // Input                                    
    // input fixed point data
    input   logic           [BUS_NUM-1:0][FIXED_BIT-1:0]        in_fixed_data,
    input   logic           [BUS_NUM-1:0]                       in_fixed_data_vld,
    
    // output fixed point data scale position
    input   logic signed    [SCALA_POS_WIDTH-1:0]               out_scale_pos, //-16 ~ 15
    input   logic                                               out_scale_pos_vld,

    // LUT Interface_
    input   logic           [LUT_ADDR:0]                        lut_waddr,
    input   logic                                               lut_wen,
    input   logic           [LUT_DATA-1:0]                      lut_wdata,

    // Output
    // output fixed point data
    output  logic           [BUS_NUM-1:0][FIXED_BIT-1:0]        out_fixed_data,
    output  logic           [BUS_NUM-1:0]                       out_fixed_data_vld
    // output  logic                                               out_fixed_data_last //This signal is to help to design more efficiently
)
    genvar i;
    generate;
        for (int i = 0; i < `BUS_NUM; i++) begin
            consmax_block #(
                .FIXED_BIT(FIXED_BIT),
                .EXP_BIT(EXP_BIT),
                .MAT_BIT(MAT_BIT),
                .DATA_NUM_WIDTH(DATA_NUM_WIDTH),
                .SCALA_POS_WIDTH(SCALA_POS_WIDTH),
                .isize(isize),
                .isign(isign),
                .ieee_compliance(ieee_compliance)
            ) consmax_inst (
                .clk(clk),
                .rst(rst_n),
                .in_fixed_data(in_fixed_data[i]),
                .in_fixed_data_vld(in_fixed_data_vld[i]),
                .out_scale_pos(out_scale_pos),
                .out_scale_pos_vld(out_scale_pos_vld),
                .lut_waddr(lut_waddr),
                .lut_wen(lut_wen),
                .lut_wdata(lut_wdata),
                .out_fixed_data(out_fixed_data[i]),
                .out_fixed_data_vld(out_fixed_data_vld[i])
            );
        end 
    endgenerate

endmodule

module consmax_block #(
    parameter   FIXED_BIT = 8,  // Fixed point width, fixed parameter

    parameter   EXP_BIT = 8,    // Exponent
    parameter   MAT_BIT = 7,    // Mantissa
    parameter   LUT_DATA  = EXP_BIT + MAT_BIT + 1,  // LUT Data Width (in FP)
    parameter   LUT_ADDR  = FIXED_BIT >> 1,         // LUT Address Width
    parameter   LUT_DEPTH = 2 ** LUT_ADDR,           // LUT Depth for INT2FP

    parameter integer DATA_NUM_WIDTH =  10, // vector length reg width
    parameter integer SCALA_POS_WIDTH = 5,  // fixed point scale position width

    localparam        isize = 32,
    localparam        isign = 1, //signed integer number
    localparam        ieee_compliance = 0 //No support to NaN adn denormals
)(
    // Global Signals
    input   logic                                               clk,
    input   logic                                               rst_n,

    // Input
    // input fixed point data
    input   logic           [FIXED_BIT-1:0]                     in_fixed_data,
    input   logic                                               in_fixed_data_vld,

    // output fixed point data scale position
    input   logic signed    [SCALA_POS_WIDTH-1:0]               out_scale_pos, //-16 ~ 15
    input   logic                                               out_scale_pos_vld,

    // LUT Interface_
    input   logic           [LUT_ADDR:0]                        lut_waddr,
    input   logic                                               lut_wen,
    input   logic           [LUT_DATA-1:0]                      lut_wdata,

    // Output
    // output fixed point data
    output  logic           [FIXED_BIT-1:0]                     out_fixed_data,
    output  logic                                               out_fixed_data_vld
)

    logic   [FIXED_BIT-1:0]             in_fixed_data_reg;
    logic                               in_fixed_data_vld_reg;
    logic signed [SCALA_POS_WIDTH-1:0]  out_scale_pos_reg;
    // logic                               out_scale_pos_vld_reg;
    logic   [LUT_ADDR:0]                lut_waddr_reg;
    logic                               lut_wen_reg
    logic   [LUT_DATA-1:0]              lut_wdata_reg;


    // 1. Clock Gating for Input
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_fixed_data_reg <= 0;
        end else if (in_fixed_data_vld) begin
            in_fixed_data_reg <= in_fixed_data;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_scale_pos_reg   <= 0;
        end else if (out_scale_pos_vld) begin
            out_scale_pos_reg   <= out_scale_pos;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_fixed_data_vld_reg   <= 0;
            // out_scale_pos_vld_reg   <= 0;
            lut_waddr_reg           <= 0;
            lut_wen_reg             <= 0;
            lut_wdata_reg           <= 0;
        end else begin
            in_fixed_data_vld_reg   <= in_fixed_data_vld;
            // out_scale_pos_vld_reg   <= out_scale_pos_vld;
            lut_waddr_reg           <= 0;
            lut_wen_reg             <= 0;
            lut_wdata_reg           <= lut_wdata;
        end
    end

    // 2. get results from the luts
    logic   [LUT_ADDR-1:0]  lut_addr    [0:1]; 
    logic   [LUT_DATA-1:0]  lut_rdata   [0:1];
    logic                   lut_ren;
    logic                   lut_rvalid;
    logic                   lut_wen_array [0:1];
    // choose the write data if wen asserted and the corresponding write addr is chosen
    assign  lut_addr[0] = (lut_wen_reg && ~lut_waddr_reg[LUT_ADDR]) ? lut_waddr_reg[LUT_ADDR-1:0] :
                                                            in_fixed_data_reg[LUT_ADDR-1:0];
    assign  lut_addr[1] = (lut_wen_reg &&  lut_waddr_reg[LUT_ADDR]) ? lut_waddr_reg[LUT_ADDR-1:0] :
                                                            in_fixed_data_reg[LUT_ADDR+:LUT_ADDR];
    // read the lut data if the input data is valid
    assign  lut_ren     = lut_wen_reg ? 0 : in_fixed_data_vld_reg;
    assign  lut_wen_array[0] = lut_wen_reg && ~lut_waddr_reg[LUT_ADDR];
    assign  lut_wen_array[1] = lut_wen_reg && lut_waddr_reg[LUT_ADDR];

    genvar i;
    generate;
        for (i = 0; i < 2; i = i + 1) begin: gen_conmax_lut
            mem_sp #(
                .DATA_BIT(16),
                .DEPTH(16)
            ) lut_inst  (
                .clk(clk),
                .addr(lut_addr[i]),
                .wen(lut_wen_array[i]),
                .wdata(lut_wdata_reg),
                .ren(lut_ren),
                .rdata(lut_rdata[i])
            );
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_rvalid <= 1'b0;
        end
        else begin
            lut_rvalid <= lut_ren;
        end
    end

    // 3. multiply stage, produce exp(Si)
    logic                   exp_rst_vld;
    logic   [LUT_DATA-1:0]  exp_rst;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            exp_rst_vld <= 1'b0;
        end
        else begin
            exp_rst_vld <= lut_rvalid;
        end
    end

    DW_fp_mult #(MAT_BIT, EXP_BIT, 0, 0)
                mult_fp ( .a(lut_rdata[0]), .b(lut_rdata[1]), .rnd(3'b000), .z(exp_rst));

    // 4. convert FLOAT to FixPoint
    logic                   exp_rst_scaled_vld;
    logic   [LUT_DATA-1:0]  exp_rst_scaled;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            exp_rst_scaled_vld <= 1'b0;
            out_fixed_data_vld <= 1'b0;
        end
        else if (exp_rst_vld) begin
            exp_rst_scaled_vld <= exp_rst_vld;
            out_fixed_data_vld <= exp_rst_vld;
        end
    end

    always_comb begin
        exp_rst_scaled[MAT_BIT+EXP_BIT-1:0] = exp_rst[MAT_BIT+EXP_BIT-1:0] + $signed({out_scale_pos_reg,{MAT_BIT{1'b0}}});
        exp_rst_scaled[MAT_BIT+EXP_BIT] = exp_rst[MAT_BIT+EXP_BIT];
    end

    DW_fp_flt2i #(MAT_BIT, EXP_BIT, isize, isign)
        flt2i_out_data (
            .a(exp_rst_scaled),
            .rnd(3'b000),
            .z(out_fixed_data),
            .status()
        );

endmodule

module mem_sp #(
    parameter   DATA_BIT = 64,
    parameter   DEPTH = 1024,
    parameter   ADDR_BIT = $clog2(DEPTH)
)(
    // Global Signals
    input                       clk,

    // Data Signals
    input       [ADDR_BIT-1:0]  addr,
    input                       wen,
    input       [DATA_BIT-1:0]  wdata,
    input                       ren,
    output  reg [DATA_BIT-1:0]  rdata
);

    // 1. RAM/Memory initialization
    reg [DATA_BIT-1:0]  mem [0:DEPTH-1];

    // 2. Write channel
    always @(posedge clk) begin
        if (wen) begin
            mem[addr] <= wdata;
        end
    end

    // 3. Read channel
    always @(posedge clk) begin
        if (ren) begin
            rdata <= mem[addr];
        end
    end

endmodule