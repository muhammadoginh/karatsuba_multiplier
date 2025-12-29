`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2025 08:30:36 PM
// Design Name: 
// Module Name: poly_mult_control
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


module poly_mult_control #(
        parameter N_LIMBS = 277  // ceil(17669 / 64)
    )(
        input                   clk,
        input                   rstn,
        input                   start,
        input                   valid_in,       // From host: high when a,b are valid
        output reg              done,
        output reg              load_a_b,       // Load a,b into registers
        output reg [9:0]        i_index,        // i in [0, N_LIMBS-1]
        output reg [9:0]        j_index,        // j in [0, N_LIMBS-1]
        output reg              accum_en,       // Accumulate after mul64
        output reg              valid_out       // Optional: echo valid
    );

    localparam IDLE      = 2'd0;
    localparam LOAD_AB   = 2'd1;
    localparam ACCUM     = 2'd2;
    localparam FINISH    = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (~rstn) begin
            state <= IDLE;
            done <= 0;
            load_a_b <= 0;
            accum_en <= 0;
            valid_out <= 0;
            i_index <= 0;
            j_index <= 0;
        end else begin
            load_a_b <= 0;
            accum_en <= 0;
            valid_out <= 0;
            done <= 0;

            case (state)
                IDLE: begin
                    if (start) begin
                        i_index <= 0;
                        j_index <= 0;
                        state <= LOAD_AB;
                    end
                end

                LOAD_AB: begin
                    // Request new limb pair (a_i, b_j)
                    load_a_b <= 1;
                    valid_out <= 1;
                    // Wait for valid input from host
                    if (valid_in) begin
                        state <= ACCUM;
                    end
                end

                ACCUM: begin
                    // Signal datapath to accumulate mul64 result
                    accum_en <= 1;
                    // Advance to next (i,j)
                    if (j_index == N_LIMBS - 1) begin
                        j_index <= 0;
                        if (i_index == N_LIMBS - 1) begin
                            state <= FINISH;
                        end else begin
                            i_index <= i_index + 1;
                        end
                    end else begin
                        j_index <= j_index + 1;
                    end
                    state <= LOAD_AB;
                end

                FINISH: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
