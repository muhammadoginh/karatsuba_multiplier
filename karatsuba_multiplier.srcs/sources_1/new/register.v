`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2025 10:20:06 PM
// Design Name: 
// Module Name: register
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


module register #(
        parameter BW = 64
    )(
        input                   clk,
        input                   rstn,
        input                   load,
        input       [BW - 1:0]  in,
        output reg  [BW - 1:0]  out
    );
    
    always @(posedge clk) begin
        if (~rstn) begin
            out <= 0;
        end else if (load) begin
            out <= in;
        end
    end
    
endmodule
