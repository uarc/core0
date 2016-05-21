module alu(
  a,
  b,
  ic,
  opcode,
  out,
  oc,
  oo,
);
  /// The magnitude of the width
  parameter WIDTH_MAG = 5;
  localparam WIDTH = 1 << WIDTH_MAG;

  localparam
    OP_LSL = 3'h0,
    OP_LSR = 3'h1,
    OP_CSL = 3'h2,
    OP_CSR = 3'h3,
    OP_ASR = 3'h4,
    OP_AND = 3'h5,
    OP_OR = 3'h6,
    OP_ADD = 3'h7;

  /// The first parameter in a mathematical operation
  input [WIDTH-1:0] a;
  /// The second parameter in a mathematical operation (often top of stack)
  input [WIDTH-1:0] b;
  /// Input carry bit
  input ic;
  /// Opcode which determines the operation
  input [2:0] opcode;
  /// Primary output of the operation
  output reg [WIDTH-1:0] out;
  /// Output carry bit
  output reg oc;
  /// Output overflow bit
  output reg oo;

  wire [WIDTH:0] sum;

  assign sum = a + b;

  always @* begin
    case (opcode)
      OP_LSL: begin
        out = a << b;
        oc = 1'bx;
        oo = 1'bx;
      end
      OP_LSR: begin
        out = a >> b;
        oc = 1'bx;
        oo = 1'bx;
      end
      OP_CSL: begin
        out = {a, a} >> (WIDTH - b[WIDTH_MAG-1:0]);
        oc = 1'bx;
        oo = 1'bx;
      end
      OP_CSR: begin
        out = {a, a} >> b[WIDTH_MAG-1:0];
        oc = 1'bx;
        oo = 1'bx;
      end
      OP_ASR: begin
        out = $signed(a) >>> b;
        oc = 1'bx;
        oo = 1'bx;
      end
      OP_AND: begin
        out = a & b;
        oc = 1'bx;
        oo = 1'bx;
      end
      OP_OR: begin
        out = a | b;
        oc = 1'bx;
        oo = 1'bx;
      end
      OP_ADD: begin
        {oc, out} = sum;
        oo = a[WIDTH-1] == b[WIDTH-1] && sum[WIDTH-1] != a[WIDTH-1];
      end
    endcase
  end
endmodule
