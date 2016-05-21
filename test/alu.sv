`include "../src/alu.sv"

module alu_test;
  reg [31:0] a;
  reg [31:0] b;
  reg ic;
  reg [2:0] opcode;
  wire [31:0] out;
  wire oc;
  wire oo;

  alu #(.WIDTH_MAG(5)) alu(
    .a,
    .b,
    .ic,
    .opcode,
    .out,
    .oc,
    .oo
  );

  initial begin
    a = 32'h00010000;
    b = 32'h00010000;
    ic = 1'bx;
    opcode = 3'h0;
    #1;
    $display("Logical left shift test 1: %s", out == 32'h0 ? "pass" : "fail");

    a = 32'h80009000;
    b = 32'h1;
    ic = 0;
    opcode = 3'h0;
    #1;
    $display("Logical left shift test 2: %s", out == 32'h00012000 ? "pass" : "fail");

    a = 32'h80009000;
    b = 32'h00010000;
    ic = 0;
    opcode = 3'h1;
    #1;
    $display("Logical right shift test 1: %s", out == 32'h0 ? "pass" : "fail");

    a = 32'h80009000;
    b = 32'h1;
    ic = 0;
    opcode = 3'h1;
    #1;
    $display("Logical right shift test 2: %s", out == 32'h40004800 ? "pass" : "fail");

    a = 32'h80009001;
    b = 32'h1;
    ic = 0;
    opcode = 3'h2;
    #1;
    $display("Circular shift left test: %s", out == 32'h00012003 ? "pass" : "fail");

    a = 32'h80009001;
    b = 32'h1;
    ic = 0;
    opcode = 3'h3;
    #1;
    $display("Circular shift right test: %s", out == 32'hC0004800 ? "pass" : "fail");

    a = 32'h80009000;
    b = 32'h1;
    ic = 0;
    opcode = 3'h4;
    #1;
    $display("Arithmetic shift right test: %s", out == 32'hC0004800 ? "pass" : "fail");

    a = 32'h80109001;
    b = 32'hFFFF0000;
    ic = 0;
    opcode = 3'h5;
    #1;
    $display("And test: %s", out == 32'h80100000 ? "pass" : "fail");

    a = 32'h80109001;
    b = 32'hFFFF0000;
    ic = 0;
    opcode = 3'h6;
    #1;
    $display("Or test: %s", out == 32'hFFFF9001 ? "pass" : "fail");

    a = 32'h00001000;
    b = 32'h00008000;
    ic = 0;
    opcode = 3'h7;
    #1;
    $display("Add test: %s", out == 32'h00009000 ? "pass" : "fail");

    a = 32'h80001000;
    b = 32'h00008000;
    ic = 0;
    opcode = 3'h7;
    #1;
    $display("Negative test: %s", out == 32'h80009000 ? "pass" : "fail");

    a = 32'h80001000;
    b = 32'h80008000;
    ic = 0;
    opcode = 3'h7;
    #1;
    $display("Carry test: %s", out == 32'h00009000 && oc == 1 ? "pass" : "fail");

    a = 32'h80001000;
    b = 32'h80008000;
    ic = 0;
    opcode = 3'h7;
    #1;
    $display("Overflow test 1: %s", oo == 1 ? "pass" : "fail");

    a = 32'h80001000;
    b = 32'h00008000;
    ic = 0;
    opcode = 3'h7;
    #1;
    $display("Overflow test 2: %s", oo == 0 ? "pass" : "fail");

    a = 32'h70001000;
    b = 32'h70008000;
    ic = 0;
    opcode = 3'h7;
    #1;
    $display("Overflow test 3: %s", oo == 1 ? "pass" : "fail");
  end
endmodule
