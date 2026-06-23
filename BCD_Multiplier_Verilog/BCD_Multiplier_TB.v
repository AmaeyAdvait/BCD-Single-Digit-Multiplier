// Programmer's Log: BCD_Multiplier_TB.v
// A rigorous testbed. Exhaustively tests all 0-9 x 0-9 products using the EXACT keypad protocol:
// press digit1, press E (separator, discarded by hardware), press digit2.
// Resets between trials for clarity (mirrors a "clear" keypress in practice).

`timescale 1ns/1ps //Programmer's Log: Here, I was hit with a testbench race condition, 
                   //not a design bug. I realised I was deasserting load_a/load_b in the same
                   //simulation timestep as the clock edge, which raced against the 
                   //DUT(Design under Test)'s synchronous register update. 
                   
                   //Fixed by adding a 1ns delay before changing control signals after 
                   //@(posedge clk). Genuinely felt like modelling a real world scenario. Wasn't
                   //successful the first time of course, but arguably more engineered
                   //than trial and error like walking through the breadboard with a probe wire!

module BCD_multiplier_TB;

    reg clk, rst, strobe;
    reg [3:0] keypad_in;
    wire [6:0] seg_tens, seg_units;
    wire [7:0] product_debug;

    integer i, j, expected, exp_tens, exp_units;
    integer errors;

    BCD_multiplier_memory uut (
        .clk(clk),
        .rst(rst),
        .strobe(strobe),
        .keypad_in(keypad_in),
        .seg_tens(seg_tens),
        .seg_units(seg_units),
        .product_debug(product_debug)
    );

    initial clk = 0;
    always #5 clk = ~clk; //infinite clock generator

    task press_key(input [3:0] key);
        begin
            keypad_in = key;
            strobe = 1;
            @(posedge clk);
            #1;
            strobe = 0;
            @(posedge clk); // one idle cycle between presses, like a real keypad
        end
    endtask

    initial begin
        $dumpfile("bcd_multiplier.vcd");
        $dumpvars(0, BCD_multiplier_TB);

        errors = 0;
        rst = 1; strobe = 0; keypad_in = 0;
        @(posedge clk); @(posedge clk);
        rst = 0;
        @(posedge clk);

        for (i = 0; i <= 9; i = i + 1) begin
            for (j = 0; j <= 9; j = j + 1) begin

                // reset pipeline before each trial (mirrors pressing 'clear/repeatedly pressing 0!')
                rst = 1; @(posedge clk); rst = 0; @(posedge clk);

                // replicates exact hardware protocol: digit1, E, digit2
                press_key(i);
                press_key(4'hE);
                press_key(j);

                #1;

                expected  = i * j;
                exp_tens  = expected / 10;
                exp_units = expected % 10;

                if (product_debug !== expected) begin
                    $display("MISMATCH (binary): %0d x %0d => got %0d, expected %0d",
                              i, j, product_debug, expected);
                    errors = errors + 1;
                end

                if (uut.tens !== exp_tens || uut.units !== exp_units) begin
                    $display("MISMATCH (BCD): %0d x %0d => got tens=%0d units=%0d, expected tens=%0d units=%0d",
                              i, j, uut.tens, uut.units, exp_tens, exp_units);
                    errors = errors + 1;
                end

            end
        end

        if (errors == 0)
            $display("ALL 100 TEST CASES PASSED via digit-E-digit keypad protocol.");
        else
            $display("%0d MISMATCHES FOUND.", errors);

        #20;
        $finish;
    end

endmodule