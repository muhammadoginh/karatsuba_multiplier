`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2025 04:43:41 PM
// Design Name: 
// Module Name: mul64_tb
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


module mul64_tb();
    // Parameter matching your module
    localparam BW = 64;
    
    // DUT ports
    reg                  clk;
    reg                  rstn;
    reg  [BW-1:0]        a;
    reg  [BW-1:0]        b;
    wire [2*BW-1:0]      product;

    // Clock generator
    always #5 clk = ~clk; // 100 MHz clock
    
    // Instantiate DUT
    mul64 #(.BW(BW)) dut (
        .clk(clk),
        .rstn(rstn),
        .a(a),
        .b(b),
        .prod(product)
    );
    
    

    // Task to run a single GF(2) multiplication test
    task test_gf2_mul;
        input [BW-1:0] test_a, test_b;
        input [2*BW-1:0] expected;
        begin
            a = test_a;
            b = test_b;
            @(posedge clk); // Launch inputs
            if (product !== expected) begin
                $display("FAIL: %0d * %0d = %0d (expected %0d)", 
                         test_a, test_b, product, expected);
                $finish;
            end else begin
                $display("PASS: %0d * %0d = %0d", test_a, test_b, product);
            end
        end
    endtask

    // Main test sequence
    initial begin
        $display("Starting GF(2) carry-less multiplication tests...");
        clk = 0;
        rstn = 0;
        a = 0;
        b = 0;
        #20;
        rstn = 1;
        @(posedge clk); // Launch inputs

        // Test 1: 5 * 5 = 17 (x^2+1)^2 = x^4 + 1 ¡æ 0b10001 = 17
        test_gf2_mul(64'd5, 64'd5, 128'd17);

        // Test 2: 8 * 8 = 64 (x^3 * x^3 = x^6 ¡æ 2^6 = 64)
        test_gf2_mul(64'd8, 64'd8, 128'd64);

        // Test 3: 3 * 3 = 5 (x+1)^2 = x^2 + 1 ¡æ 0b101 = 5
        test_gf2_mul(64'd3, 64'd3, 128'd5);

        // Test 4: 1 * any = any
        test_gf2_mul(64'd1, 64'd12345, 128'd12345);

        // Test 5: 0 * any = 0
        test_gf2_mul(64'd123, 64'd123, 128'd5445);

        // Test 6: High-bit test (2^63 * 2^63 = 2^126)
        test_gf2_mul(64'h8000000000000000, 64'h8000000000000000, 128'h40000000000000000000000000000000);

        $display("All tests passed!");
        #100;
        $finish;
    end
endmodule
