`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2025 08:26:14 PM
// Design Name: 
// Module Name: mul64_v2_tb
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


module mul64_v2_tb();

    // Parameter: must match DUT
    localparam BW = 64;
    localparam OUTW = 2 * BW;

    // Clock and reset
    reg clk;
    reg rstn;

    // DUT ports
    reg  [BW-1:0]      a;
    reg  [BW-1:0]      b;
    wire [OUTW-1:0]    prod;

    // Clock generator (100 MHz => 10ns period; adjust if needed for 7ns)
    always #5 clk = ~clk;  // 10ns period = 100 MHz (safe for timing tests)

    // DUT instantiation
    mul64 #(.BW(BW)) dut (
        .clk(clk),
        .rstn(rstn),
        .a(a),
        .b(b),
        .prod(prod)
    );

    // Task: apply inputs and check output after 1 cycle
    task test_gf2;
        input [BW-1:0] test_a, test_b;
        input [OUTW-1:0] expected;
        begin
            a = test_a;
            b = test_b;
            @(posedge clk);  // Launch inputs
            @(posedge clk);  // Capture result (1-cycle latency)
            if (prod !== expected) begin
                $display("FAIL at time %0t: %0d * %0d = %0d (expected %0d)",
                         $time, test_a, test_b, prod, expected);
                $stop;
            end else begin
                $display("PASS at time %0t: %0d * %0d = %0d",
                         $time, test_a, test_b, prod);
            end
        end
    endtask

    // Convert integer to expected GF(2) product (for small values)
    function [OUTW-1:0] gf2_ref;
        input [BW-1:0] x, y;
        reg [OUTW-1:0] res;
        integer i;
        begin
            res = 0;
            for (i = 0; i < BW; i = i + 1) begin
                if (y[i])
                    res = res ^ (x << i);
            end
            gf2_ref = res;
        end
    endfunction

    // Main test sequence
    initial begin
        // Initialize
        clk = 0;
        rstn = 0;
        a = 0;
        b = 0;

        // Reset sequence
        #20;
        rstn = 1;
        #10;

        $display("Starting GF(2) carry-less multiplication tests (BW=%0d)...", BW);

        // Test 1: 5 * 5 = 17  (x^2+1)^2 = x^4 + 1
        test_gf2(64'd5, 64'd5, gf2_ref(64'd5, 64'd5));

        // Test 2: 8 * 8 = 64  (x^3 * x^3 = x^6)
        test_gf2(64'd8, 64'd8, gf2_ref(64'd8, 64'd8));

        // Test 3: 3 * 3 = 5   (x+1)^2 = x^2 + 1
        test_gf2(64'd3, 64'd3, gf2_ref(64'd3, 64'd3));

        // Test 4: 1 * N = N
        test_gf2(64'd1, 64'd12345, gf2_ref(64'd1, 64'd12345));

        // Test 5: 0 * any = 0
        test_gf2_mul(64'd123, 64'd123, 128'd5445);

        $display("All tests passed!");
        $finish;
    end

endmodule
