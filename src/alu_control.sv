`include "../src/instructions.sv"
`include "../src/alu_opcodes.sv"

module alu_control(
  instruction,
  second,
  carry,
  dcs,
  dc_vals,

  alu_a,
  alu_ic,
  alu_opcode,

  store_carry,
  store_overflow,
);
  parameter WORD_WIDTH = 32;

  input [7:0] instruction;
  input [WORD_WIDTH-1:0] second;
  input carry;
  input [3:0][WORD_WIDTH-1:0] dcs;
  input [3:0][WORD_WIDTH-1:0] dc_vals;

  output reg [WORD_WIDTH-1:0] alu_a;
  output reg alu_ic;
  output reg [3:0] alu_opcode;
  output reg store_carry, store_overflow;

  always @* begin
    casez (instruction)
      `I_RREADZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_ic = 0;
        alu_opcode = `OP_ADD;
        store_carry = 0;
        store_overflow = 0;
      end
      `I_ADDZ: begin
        alu_a = dc_vals[instruction[1:0]];
        alu_ic = 0;
        alu_opcode = `OP_ADD;
        store_carry = 1;
        store_overflow = 1;
      end
      `I_INC: begin
        alu_a = 1;
        alu_ic = 0;
        alu_opcode = `OP_ADD;
        store_carry = 1;
        store_overflow = 1;
      end
      `I_DEC: begin
        alu_a = -1;
        alu_ic = 0;
        alu_opcode = `OP_ADD;
        store_carry = 1;
        store_overflow = 1;
      end
      `I_CARRY: begin
        alu_a = 0;
        alu_ic = carry;
        alu_opcode = `OP_ADD;
        store_carry = 1;
        store_overflow = 1;
      end
      `I_BORROW: begin
        alu_a = -1;
        alu_ic = carry;
        alu_opcode = `OP_ADD;
        store_carry = 1;
        store_overflow = 1;
      end
      `I_INV: begin
        alu_a = -1;
        alu_ic = 0;
        alu_opcode = `OP_XOR;
        store_carry = 0;
        store_overflow = 0;
      end
      `I_ADD: begin
        alu_a = second;
        alu_ic = 0;
        alu_opcode = `OP_ADD;
        store_carry = 1;
        store_overflow = 1;
      end
      `I_ADDC: begin
        alu_a = second;
        alu_ic = carry;
        alu_opcode = `OP_ADD;
        store_carry = 1;
        store_overflow = 1;
      end
      `I_SUB: begin
        alu_a = ~second;
        alu_ic = 1;
        alu_opcode = `OP_ADD;
        store_carry = 1;
        store_overflow = 1;
      end
      `I_SUBC: begin
        alu_a = ~second;
        alu_ic = carry;
        alu_opcode = `OP_ADD;
        store_carry = 1;
        store_overflow = 1;
      end
      `I_LSL: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_LSL;
        store_carry = 0;
        store_overflow = 0;
      end
      `I_LSR: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_LSR;
        store_carry = 0;
        store_overflow = 0;
      end
      `I_CSL: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_CSL;
        store_carry = 0;
        store_overflow = 0;
      end
      `I_CSR: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_CSR;
        store_carry = 0;
        store_overflow = 0;
      end
      `I_ASR: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_ASR;
        store_carry = 0;
        store_overflow = 0;
      end
      `I_AND: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_AND;
        store_carry = 0;
        store_overflow = 0;
      end
      `I_OR: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_OR;
        store_carry = 0;
        store_overflow = 0;
      end
      `I_XOR: begin
        alu_a = second;
        alu_ic = 1'bx;
        alu_opcode = `OP_XOR;
        store_carry = 0;
        store_overflow = 0;
      end
      `I_RWRITEZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_ic = 0;
        alu_opcode = `OP_ADD;
        store_carry = 0;
        store_overflow = 0;
      end
      default: begin
        alu_a = {WORD_WIDTH{1'bx}};
        alu_ic = 1'bx;
        alu_opcode = `OP_NOP;
        store_carry = 0;
        store_overflow = 0;
      end
    endcase
  end
endmodule
