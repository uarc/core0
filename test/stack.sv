`include "../src/stack.sv"

module stack_test;
  reg clk;
  reg push;
  reg pop;
  reg [31:0] insert;
  wire [31:0] top;

  stack #(.WIDTH(32), .DEPTH(8)) stack(
    .clk,
    .push,
    .pop,
    .insert,
    .top
  );

  reg test_failure;

  initial begin
    for (int i = 0; i < 8; i++) begin
      push = 1;
      pop = 0;
      insert = i;
      clk = 0; #1; clk = 1; #1;
    end

    test_failure = 0;

    for (int i = 0; i < 8; i++) begin
      if (top != 7-i)
        test_failure = 1;
      push = 0;
      pop = 1;
      clk = 0; #1; clk = 1; #1;
    end

    if (test_failure)
      $display("Test failed");
    else
      $display("Test passed");
  end
endmodule
