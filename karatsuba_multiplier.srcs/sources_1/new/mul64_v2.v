`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2025 08:24:29 PM
// Design Name: 
// Module Name: mul64_v2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mul64_v2  #(
        parameter BW = 64
    )(
        input                clk,
        input                rstn,
        input   [BW-1:0]     a,
        input   [BW-1:0]     b,
        output  [2*BW-1:0]   prod
    );

    localparam OUTW = 2 * BW;

    // Input registers
    reg [BW-1:0] a_reg;
    reg [BW-1:0] b_reg;

    // Output register
    reg [OUTW-1:0] prod_reg;

    // Accumulator for result (combinational)
    wire [OUTW-1:0] product_comb;

    // Use a single reduction loop with conditional XOR
    // More efficient than generating all partial products
    genvar i;
    wire [OUTW-1:0] acc [0:BW];
    
    // Base: acc[0] = 0
    assign acc[0] = {OUTW{1'b0}};
    
    // Iteratively accumulate: acc[i+1] = acc[i] ^ (a[i] ? (b << i) : 0)
    generate
        for (i = 0; i < BW; i = i + 1) begin : accumulate
            wire [OUTW-1:0] shifted_b = { {BW{1'b0}}, b_reg } << i;
            wire [OUTW-1:0] masked_b = {OUTW{a_reg[i]}} & shifted_b;
            assign acc[i+1] = acc[i] ^ masked_b;
        end
    endgenerate

    assign product_comb = acc[BW];

    // Input pipeline
    always @(posedge clk) begin
        if (~rstn) begin
            a_reg <= {BW{1'b0}};
            b_reg <= {BW{1'b0}};
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Output register
    always @(posedge clk) begin
        if (~rstn)
            prod_reg <= {OUTW{1'b0}};
        else
            prod_reg <= product_comb;
    end

    assign prod = prod_reg;

endmodule
