`include "../src/alu_opcodes.sv"

module alu(
  a,
  b,
  ic,
  opcode,
  out,
  oc,
  oo
);
  /// The magnitude of the width
  parameter WIDTH_MAG = 5;
  localparam WIDTH = 1 << WIDTH_MAG;

  /// The first parameter in a mathematical operation
  input [WIDTH-1:0] a;
  /// The second parameter in a mathematical operation (often top of stack)
  input [WIDTH-1:0] b;
  /// Input carry bit
  input ic;
  /// Opcode which determines the operation
  input [3:0] opcode;
  /// Primary output of the operation
  output reg [WIDTH-1:0] out;
  /// Output carry bit
  output reg oc;
  /// Output overflow bit
  output reg oo;

  wire [WIDTH:0] sum;

  assign sum = a + b + ic;

  always @* begin
    case (opcode)
      `OP_LSL: begin
        out = a << b;
        oc = 1'bx;
        oo = 1'bx;
      end
      `OP_LSR: begin
        out = a >> b;
        oc = 1'bx;
        oo = 1'bx;
      end
      `OP_CSL: begin
        out = {a, a} >> (WIDTH - b[WIDTH_MAG-1:0]);
        oc = 1'bx;
        oo = 1'bx;
      end
      `OP_CSR: begin
        out = {a, a} >> b[WIDTH_MAG-1:0];
        oc = 1'bx;
        oo = 1'bx;
      end
      `OP_ASR: begin
        out = $signed(a) >>> b;
        oc = 1'bx;
        oo = 1'bx;
      end
      `OP_AND: begin
        out = a & b;
        oc = 1'bx;
        oo = 1'bx;
      end
      `OP_OR: begin
        out = a | b;
        oc = 1'bx;
        oo = 1'bx;
      end
      `OP_XOR: begin
        out = a ^ b;
        oc = 1'bx;
        oo = 1'bx;
      end
      `OP_ADD: begin
        {oc, out} = sum;
        oo = a[WIDTH-1] == b[WIDTH-1] && sum[WIDTH-1] != a[WIDTH-1];
      end
      default: begin
        out = {WIDTH{1'bx}};
        oc = 1'bx;
        oo = 1'bx;
      end
    endcase
  end
endmodule
