// Programmer's Log: BCD_Multiplier_binary_mult.v
// This module is a 4x4 unsigned binary multiplier built from adders and fundamental logic gates.

// Structure: 4x AND-array (4x IC7408)
// shift-add reduction using 3 explicit 4-bit adders (3x IC7483/74283).

module full_adder(
    input  a, b, cin,
    output sum, cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

module half_adder(
    input  a, b,
    output sum, cout
);
    assign sum  = a ^ b;
    assign cout = a & b;
endmodule

// 4-bit ripple-carry adder = one IC7483/74283
module adder4(
    input  [3:0] A,
    input  [3:0] B,
    input  Cin,
    output [3:0] Sum,
    output Cout
);
    wire c1, c2, c3;
    full_adder fa0(.a(A[0]), .b(B[0]), .cin(Cin), .sum(Sum[0]), .cout(c1));
    full_adder fa1(.a(A[1]), .b(B[1]), .cin(c1),  .sum(Sum[1]), .cout(c2));
    full_adder fa2(.a(A[2]), .b(B[2]), .cin(c2),  .sum(Sum[2]), .cout(c3));
    full_adder fa3(.a(A[3]), .b(B[3]), .cin(c3),  .sum(Sum[3]), .cout(Cout));
endmodule

module BCD_multiplier_binary_mult(
    input  [3:0] A,
    input  [3:0] B,
    output [7:0] P
);

    // 16 partial products via four 4-input AND groups (4x IC7408)
    wire [3:0] pp0, pp1, pp2, pp3;
    assign pp0 = A & {4{B[0]}};
    assign pp1 = A & {4{B[1]}};
    assign pp2 = A & {4{B[2]}};
    assign pp3 = A & {4{B[3]}};

    // The first IC7483 calculates the partial products:
    wire sum0_bit0 = pp0[0];

    wire [3:0] s1; wire c1;
    adder4 add1(.A({1'b0, pp0[3:1]}), .B({1'b0, pp1[2:0]}), .Cin(1'b0), .Sum(s1), .Cout(c1));

    wire sum0_bit4, c1b;
    half_adder ha1(.a(s1[3]), .b(pp1[3]), .sum(sum0_bit4), .cout(c1b));
  
    wire [5:0] sum0 = {c1b, sum0_bit4, s1[2:0], sum0_bit0};

    // Second IC7483 
    wire sum1_bit0 = sum0[0];
    wire sum1_bit1 = sum0[1];
    
    wire [3:0] s2; wire c2;
    adder4 add2(.A(sum0[5:2]), .B(pp2[3:0]), .Cin(1'b0), .Sum(s2), .Cout(c2));

    wire [6:0] sum1 = {c2, s2, sum1_bit1, sum1_bit0};

    // Third IC7483
    wire sum2_bit0 = sum1[0];
    wire sum2_bit1 = sum1[1];
    wire sum2_bit2 = sum1[2];

    wire [3:0] s3; wire c3;
    adder4 add3(.A(sum1[6:3]), .B(pp3[3:0]), .Cin(1'b0), .Sum(s3), .Cout(c3));

    wire [7:0] sum2 = {c3, s3, sum2_bit2, sum2_bit1, sum2_bit0};

    assign P = sum2; //Final product in binary! This is then directly fed into the double dabble
                     //algorithm

endmodule