`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2025 08:30:50 PM
// Design Name: 
// Module Name: poly_mult
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


module poly_mult #(
        parameter BW = 64,
        parameter N_LIMBS = 277  // ceil(17669 / 64)
    )(
        input                   clk,
        input                   rstn,
        input                   start,          // Pulse to begin new multiplication
        input                   valid_in,       // High when a, b are valid
        input   [BW-1:0]        a,              // Stream: limb 0, limb 1, ..., limb N-1
        input   [BW-1:0]        b,
        output  [2*BW-1:0]      prod,           // 128-bit product of current limb pair
        output                  valid_out,      // High when prod is valid
        output                  done            // High when full 17669-bit multiply is done
    );
    
    // Internal control signals
    wire        load_a_b;
    wire        mul_start;
    wire        accum_en;
    wire [9:0]  i_index;   // 2^10 = 1024 > 2*277
    wire [9:0]  j_index;
    
    // Instantiate control unit
    poly_mult_control #(.N_LIMBS(N_LIMBS)) u_control (
        .clk(clk),
        .rstn(rstn),
        .start(start),
        .valid_in(valid_in),
        .load_a_b(load_a_b),
        .i_index(i_index),
        .j_index(j_index),
        .mul_start(mul_start),
        .accum_en(accum_en),
        .valid_out(valid_out),
        .done(done)
    );

    // Instantiate datapath (contains mul64 + accumulator)
    poly_mult_core #(.BW(BW), .N_LIMBS(N_LIMBS)) u_datapath (
        .clk(clk),
        .rstn(rstn),
        .load_a_b(load_a_b),
        .a(a),
        .b(b),
        .i_index(i_index),
        .j_index(j_index),
        .accum_en(accum_en),
        .product(prod)
    );
    
endmodule
