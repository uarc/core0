module alu(
  a,
  b,
  ic,
  opcode,
  out,
  oc,
  oo,
);
  /// The width of the operands to the alu
  parameter WIDTH = 32;

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
  output oc;
  /// Output overflow bit
  output oo;

  always @* begin
    case (opcode)
      // TODO: Add opcodes
      default: out = 0;
    endcase
  end
endmodule
