`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2025 08:30:19 PM
// Design Name: 
// Module Name: poly_mult_core
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


module poly_mult_core #(
        parameter BW = 48,
        parameter N_LIMBS = 277
    )(
        input                   clk,
        input                   rstn,
        input                   load_a_b,       // Latch new a, b
        input   [BW-1:0]        a,              // Input limb A_i
        input   [BW-1:0]        b,              // Input limb B_j
        input   [9:0]           i_index,        // i in [0, N_LIMBS-1]
        input   [9:0]           j_index,        // j in [0, N_LIMBS-1]
        input                   accum_en,       // Accumulate mul64 result now
        output  [2*BW-1:0]      product         // Partial product (for debug)
    ); 
    
    localparam OUT_LIMBS = 2 * N_LIMBS;  // 554
    localparam ADDR_WIDTH = $clog2(OUT_LIMBS); // 10 bits (2^10=1024 > 554)

    // Internal registers for a, b
    wire [BW-1:0] a_reg;
    wire [BW-1:0] b_reg;

    // Instantiation of mul64
    wire [2*BW-1:0] mul64_prod;
    mul64 #(.BW(BW)) u_mul64 (
        .clk(clk),
        .rstn(rstn),
        .a(a_reg),
        .b(b_reg),
        .prod(mul64_prod)
    );

    // Accumulator: store full 17669*2-bit result
    // Use BRAM or registers - here we use registers (for simulation)
    reg [BW-1:0] accum [0:OUT_LIMBS-1];

    // Addresses for accumulation
    wire [ADDR_WIDTH-1:0] addr0 = i_index + j_index;
    wire [ADDR_WIDTH-1:0] addr1 = addr0 + 1;

    // Latch inputs
    register #(BW)(.clk(clk), .rstn(rstn), .load(load_a_b), .in(a), .out(a_reg));
    register #(BW)(.clk(clk), .rstn(rstn), .load(load_a_b), .in(b), .out(b_reg));

    // Accumulation logic
    always @(posedge clk) begin
        if (~rstn) begin
            // Clear accumulator
            for (integer k = 0; k < OUT_LIMBS; k = k + 1)
                accum[k] <= 0;
        end else if (accum_en) begin
            // XOR low part into accum[addr0]
            accum[addr0] <= accum[addr0] ^ mul64_prod[BW-1:0];
            // XOR high part into accum[addr1] (if in range)
            if (addr1 < OUT_LIMBS)
                accum[addr1] <= accum[addr1] ^ mul64_prod[2*BW-1:BW];
        end
    end
    
    // Low part accumulator (limbs 0 to 553)
    wire [BW-1:0] accum0_rdata;
    xpm_memory_sdpram #(
        .ADDR_WIDTH_A(ADDR_WIDTH),
        .DATA_WIDTH_A(BW),
        .ECC_MODE("no_ecc"),
        .READ_RESET_VALUE_A("0")
    ) accum0_bram (
        .clk_a(clk),
        .we_a(accum_en),
        .addr_a(addr0),
        .din_a(accum0_rdata ^ mul64_prod[BW-1:0]),  // Read -> XOR -> Write
        .dout_a(accum0_rdata)
    );

    // High part accumulator (for carry limb)
    wire [BW-1:0] accum1_rdata;
    xpm_memory_sdpram #(
        .ADDR_WIDTH_A(ADDR_WIDTH),
        .DATA_WIDTH_A(BW),
        .ECC_MODE("no_ecc"),
        .READ_RESET_VALUE_A("0")
    ) accum1_bram (
        .clk_a(clk),
        .we_a(accum_en && (addr1 < OUT_LIMBS)),
        .addr_a(addr1),
        .din_a(accum1_rdata ^ mul64_prod[2*BW-1:BW]),
        .dout_a(accum1_rdata)
    );

    // Output product (for debug or forwarding)
    assign product = mul64_prod;
    
    
endmodule
