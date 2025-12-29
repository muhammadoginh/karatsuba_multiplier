`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2025 02:55:21 PM
// Design Name: 
// Module Name: mul64
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: GF2
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mul64 #(
        parameter BW = 64
    )(
        input                clk,
        input                rstn,
        input   [BW - 1:0]   a,
        input   [BW - 1:0]   b,
        output  [BW*2 - 1:0] prod
    );
    
    reg [BW - 1:0]   a_reg;
    reg [BW - 1:0]   b_reg;
    reg [BW*2 - 1:0] prod_reg;
    
    // Temporary array to hold partial products
    wire [BW*2 - 1:0] pp [0:BW - 1];  // 64 partial products, each 128-bit
    
    always @(posedge clk) begin
        if (~rstn) begin
            a_reg <= 0;
            b_reg <= 0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Generate partial products: pp[i] = (a[i] ? (b << i) : 128'd0)
    genvar i;
    generate
        for (i = 0; i < BW; i = i + 1) begin : partial_products
            assign pp[i] = {{BW{1'd0}}, b_reg} << i;  // Zero-extend b to 128 bits, then shift
        end
    endgenerate

    // Now, conditionally include pp[i] only if a[i] is 1
    // We'll use a reduction XOR tree
    wire [BW*2 - 1:0] masked_pp [0:BW - 1];
    generate
        for (i = 0; i < BW; i = i + 1) begin : mask_bits
            assign masked_pp[i] = {128{a_reg[i]}} & pp[i];  // If a[i]==1, output pp[i]; else 0
        end
    endgenerate

    // Reduction XOR: XOR all masked_pp together
    // We do this hierarchically to avoid deep XOR chains (helps timing)
    wire [127:0] xor_stage0 [0:31];
    wire [127:0] xor_stage1 [0:15];
    wire [127:0] xor_stage2 [0:7];
    wire [127:0] xor_stage3 [0:3];
    wire [127:0] xor_stage4 [0:1];
    wire [127:0] final_xor;

    generate
        for (i = 0; i < 32; i = i + 1) begin : red0
            assign xor_stage0[i] = masked_pp[2*i] ^ masked_pp[2*i + 1];
        end
        for (i = 0; i < 16; i = i + 1) begin : red1
            assign xor_stage1[i] = xor_stage0[2*i] ^ xor_stage0[2*i + 1];
        end
        for (i = 0; i < 8; i = i + 1) begin : red2
            assign xor_stage2[i] = xor_stage1[2*i] ^ xor_stage1[2*i + 1];
        end
        for (i = 0; i < 4; i = i + 1) begin : red3
            assign xor_stage3[i] = xor_stage2[2*i] ^ xor_stage2[2*i + 1];
        end
        for (i = 0; i < 2; i = i + 1) begin : red4
            assign xor_stage4[i] = xor_stage3[2*i] ^ xor_stage3[2*i + 1];
        end
        assign final_xor = xor_stage4[0] ^ xor_stage4[1];
    endgenerate

    assign prod = prod_reg;
    
    always @(posedge clk) begin
        if (~rstn) begin
            prod_reg <= 0;
        end else begin
            prod_reg <= final_xor;
        end
    end

endmodule
