// Programmer's Log: bcd_multiplier_memory.v
// Uses the exact implementation of the ICs 74173 and 74374 to accept a hex keypad input and
// obtain a set of three 4 bit binary numbers which will further be used in the binary mulitplier.

module BCD_multiplier_memory(
    input clk,
    input rst,
    input strobe, // single shared clock/strobe line, from hex keypad
    input  [3:0] keypad_in,
    output [6:0] seg_tens,
    output [6:0] seg_units,
    output [7:0] product_debug
);

    reg [3:0] reg_new;  // 374 Q1-4: most recently entered digit B (this cycle's keypad value)
    reg [3:0] reg_mid;  // 374 Q5-8: operand digit (D5-8 is connected to Q1-4, internal feedback)
    reg [3:0] reg_A;    // 173 Q1-4: digit delayed by 2 strobes, stable multiplicand A

    always @(posedge clk) begin //Instantiation of the physical implementation
        if (rst) begin
            reg_new <= 4'd0;
            reg_mid <= 4'd0;
            reg_A   <= 4'd0;
        end else if (strobe) begin
            reg_A   <= reg_mid;     // 173: D1-4 <= 374's Q5-8
            reg_mid <= reg_new;     // 374: D5-8 <= Q1-4 (feedback, same chip)
            reg_new <= keypad_in;   // 374: D1-4 <= keypad
        end
    end

    // A = the digit that has propagated through the full 3-stage pipeline (multiplicand)
    // B = the digit currently sitting fresh in 374's Q1-4 (multiplier) - no delay needed,
    //     it's read directly off the most recent latch, exactly as in the hardware.
    wire [3:0] A = reg_A;
    wire [3:0] B = reg_new;

    wire [7:0] P;
    BCD_multiplier_binary_mult mult_inst (
        .A(A),
        .B(B),
        .P(P)
    );
    assign product_debug = P;

    wire [3:0] tens, units;
    BCD_multiplier_double_dabble dd_inst (
        .P(P),
        .tens(tens),
        .units(units)
    );

    BCD_multiplier_bcd7seg seg_tens_inst (
        .bcd(tens),
        .seg(seg_tens)
    );

    BCD_multiplier_bcd7seg seg_units_inst (
        .bcd(units),
        .seg(seg_units)
    );

endmodule