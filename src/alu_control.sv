`include "../src/instructions.sv"
`include "../src/alu_opcodes.sv"

module alu_control(
  instruction,
  top,
  second,
  carry,
  dc_vals,

  alu_a,
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
  output reg alu_ic;
  output reg [2:0] alu_opcode;

  always @* begin
    casez (instruction)
      `I_ADDZ: begin
        alu_a = dc_vals[instruction[1:0]];
        alu_ic = 0;
        alu_opcode = `OP_ADD;
      end
      `I_INC: begin
        alu_a = 1;
        alu_ic = 0;
        alu_opcode = `OP_ADD;
      end
      `I_DEC: begin
        alu_a = -1;
        alu_ic = 0;
        alu_opcode = `OP_ADD;
      end
      `I_CARRY: begin
        alu_a = 0;
        alu_ic = carry;
        alu_opcode = `OP_ADD;
      end
      `I_BORROW: begin
        alu_a = -1;
        alu_ic = carry;
        alu_opcode = `OP_ADD;
      end
      `I_ADD: begin
        alu_a = second;
        alu_ic = 0;
        alu_opcode = `OP_ADD;
      end
      `I_ADDC: begin
        alu_a = second;
        alu_ic = carry;
        alu_opcode = `OP_ADD;
      end
      `I_SUB: begin
        alu_a = ~second;
        alu_ic = 1;
        alu_opcode = `OP_ADD;
      end
      `I_SUBC: begin
        alu_a = ~second;
        alu_ic = carry;
        alu_opcode = `OP_ADD;
      end
      `I_LSL: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_LSL;
      end
      `I_LSR: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_LSR;
      end
      `I_CSL: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_CSL;
      end
      `I_CSR: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_CSR;
      end
      `I_ASR: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_ASR;
      end
      `I_AND: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_AND;
      end
      `I_OR: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_OR;
      end
      // Make the default case OR so less stuff switches around consuming power
      default: begin
        alu_a = {WORD_WIDTH{1'bx}};
        alu_ic = 1'bx;
        alu_opcode = `OP_OR;
      end
    endcase
  end
endmodule