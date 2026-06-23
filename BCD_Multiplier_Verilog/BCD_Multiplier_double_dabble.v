// Programmer's Log: BCD_Multiplier_double_dabble.v
// This module converts 8-bit binary product P (0-81, since inputs are single BCD digits)
// into BCD (tens and units)

// Key hardware fact (for all P from 0, 1, 2 upto 81):
// the double dabble correctioncorrection (+3) can ONLY ever fire on shift stages 4,5,6,7
// Stages 0-3 are mathematically guaranteed to never need correction, since
// fewer than 4 bits have shifted into units/tens at that point - so they
// were built as plain wire shifts on hardware, needing NO adder chip.
// This is exactly why the implementation uses only four 7483's (i=1,2,3,4), not eight.

// Each of the 4 correction stages implements, per nibble:
//   Y = P[i+3] + P[i+2]*P[i+1] + P[i+2]*P[i]
// (built from 2x 7408 AND + 2x 7432 OR on hardware) to decide if nibble >= 5,
// then adds +3 via a 4-bit adder (7483) if so, before shifting left by 1.

module correction_adder(
    input  [3:0] nibble_in,
    output y_flag,            // Y = nibble_in >= 5 detector
    output [3:0] nibble_out   // corrected nibble (7483: nibble_in + 3, or passthrough)
);
    // Y = P[i+3] + P[i+2]*P[i+1] + P[i+2]*P[i]   (bit-level >=5 detector)
    assign y_flag = nibble_in[3] | (nibble_in[2] & nibble_in[1]) | (nibble_in[2] & nibble_in[0]);
    assign nibble_out = y_flag ? (nibble_in + 4'd3) : nibble_in;
endmodule


module BCD_multiplier_double_dabble(
    input  [7:0] P,
    output [3:0] tens,
    output [3:0] units
);

    // {tens(4), units(4), shift_reg(8)} register, tracked stage by stage (combinational logic)
    wire [15:0] r0, r1, r2, r3, r4, r5, r6, r7, r8;

    assign r0 = {4'b0000, 4'b0000, P};

    assign r1 = r0 << 1;
    assign r2 = r1 << 1;
    assign r3 = r2 << 1;
    assign r4 = r3 << 1; //No correction

    wire [3:0] tens_c4, units_c4, tens_c5, units_c5, tens_c6, units_c6, tens_c7, units_c7;
    wire y_tens4, y_units4, y_tens5, y_units5, y_tens6, y_units6, y_tens7, y_units7;

    //Correction No.1 at left Binary shift 5
    correction_adder ca_units_1 (.nibble_in(r4[11:8]),  .y_flag(y_units4), .nibble_out(units_c4));
    correction_adder ca_tens_1  (.nibble_in(r4[15:12]), .y_flag(y_tens4),  .nibble_out(tens_c4));
    assign r5 = {tens_c4, units_c4, r4[7:0]} << 1;

    //Correction No.2 at left Binary shift 6
    correction_adder ca_units_2 (.nibble_in(r5[11:8]),  .y_flag(y_units5), .nibble_out(units_c5));
    correction_adder ca_tens_2  (.nibble_in(r5[15:12]), .y_flag(y_tens5),  .nibble_out(tens_c5));
    assign r6 = {tens_c5, units_c5, r5[7:0]} << 1;

    //Correction No.3 at left Binary shift 7
    correction_adder ca_units_3 (.nibble_in(r6[11:8]),  .y_flag(y_units6), .nibble_out(units_c6));
    correction_adder ca_tens_3  (.nibble_in(r6[15:12]), .y_flag(y_tens6),  .nibble_out(tens_c6));
    assign r7 = {tens_c6, units_c6, r6[7:0]} << 1;

    //Correction No.4 at left Binary shift 8. From this, we get the final tens and units digits!
    correction_adder ca_units_4 (.nibble_in(r7[11:8]),  .y_flag(y_units7), .nibble_out(units_c7));
    correction_adder ca_tens_4  (.nibble_in(r7[15:12]), .y_flag(y_tens7),  .nibble_out(tens_c7));
    assign r8 = {tens_c7, units_c7, r7[7:0]} << 1;

    assign tens  = r8[15:12];
    assign units = r8[11:8];

endmodule