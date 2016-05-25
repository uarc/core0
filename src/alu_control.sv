`include "../src/instructions.sv"

module alu_control(
  instruction,
  top,
  second,
  carry,
  dc_vals,

  alu_a,
  alu_b,
  alu_ic,
  alu_opcode,
);
  parameter WORD_WIDTH = 32;

  input [7:0] instruction;
  input [WORD_WIDTH-1:0] top;
  input [WORD_WIDTH-1:0] second;
  input carry;
  input [3:0][WORD_WIDTH-1:0] dc_vals;

  output reg [WORD_WIDTH-1:0] alu_a;
  output reg [WORD_WIDTH-1:0] alu_b;
  output reg alu_ic;
  output reg [2:0] alu_opcode;

  always @* begin
    case (instruction)

      default: begin
        alu_a = {WORD_WIDTH{1'bx}};
        alu_b = {WORD_WIDTH{1'bx}};
        alu_ic = 1'bx;
        alu_opcode = 3'bx;
      end
    endcase
  end
endmodule
