`include "../src/instructions.sv"
`include "../src/alu_opcodes.sv"

module alu_control(
  instruction,
  imm,
  top,
  second,
  carry,
  pc,
  pc_advance,
  dcs,
  dc_vals,

  alu_a,
  alu_b,
  alu_ic,
  alu_opcode,

  store_carry,
  store_overflow
);
  parameter WORD_WIDTH = 32;

  input [7:0] instruction;
  input [WORD_WIDTH-1:0] imm;
  input [WORD_WIDTH-1:0] top;
  input [WORD_WIDTH-1:0] second;
  input carry;
  input [WORD_WIDTH-1:0] pc, pc_advance;
  input [3:0][WORD_WIDTH-1:0] dcs;
  input [3:0][WORD_WIDTH-1:0] dc_vals;

  output reg [WORD_WIDTH-1:0] alu_a;
  output reg [WORD_WIDTH-1:0] alu_b;
  output reg alu_ic;
  output reg [3:0] alu_opcode;
  output reg store_carry, store_overflow;

  wire [WORD_WIDTH-1:0] imm8, imm16, simm8, simm16;

  assign simm8 = {{(WORD_WIDTH-8){imm[7]}}, imm[7:0]};
  assign simm16 = {{(WORD_WIDTH-16){imm[15]}}, imm[15:0]};
  assign imm8 = {{(WORD_WIDTH-8){1'b0}}, imm[7:0]};
  assign imm16 = {{(WORD_WIDTH-16){1'b0}}, imm[15:0]};

  always @* begin
    casez (instruction)
      `I_MOVEZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_b = simm8;
        alu_ic = 1'b1;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_RAREADZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_b = top;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_REREADIZ: begin
        alu_a = dc_vals[instruction[1:0]];
        alu_b = imm8;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_INC: begin
        alu_a = {WORD_WIDTH{1'b0}};
        alu_b = top;
        alu_ic = 1'b1;
        alu_opcode = `OP_ADD;
        store_carry = 1'b1;
        store_overflow = 1'b1;
      end
      `I_DEC: begin
        alu_a = {WORD_WIDTH{1'b1}};
        alu_b = top;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b1;
        store_overflow = 1'b1;
      end
      `I_CARRY: begin
        alu_a = {WORD_WIDTH{1'b0}};
        alu_b = top;
        alu_ic = carry;
        alu_opcode = `OP_ADD;
        store_carry = 1'b1;
        store_overflow = 1'b1;
      end
      `I_BORROW: begin
        alu_a = {WORD_WIDTH{1'b1}};
        alu_b = top;
        alu_ic = carry;
        alu_opcode = `OP_ADD;
        store_carry = 1'b1;
        store_overflow = 1'b1;
      end
      `I_INV: begin
        alu_a = {WORD_WIDTH{1'b1}};
        alu_b = top;
        alu_ic = 1'bx;
        alu_opcode = `OP_XOR;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_ILOOP: begin
        alu_a = pc_advance;
        alu_b = imm16;
        alu_ic = 1'b1;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BRA: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_CALLRI: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_READZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_b = simm8;
        alu_ic = 1'b1;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_RAREADIZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_b = imm8;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_WRITEPREZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_b = simm8;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_WRITEPSTZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_b = simm8;
        alu_ic = 1'b1;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_RAWRITEIZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_b = imm8;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_REWRITEIZ: begin
        alu_a = dc_vals[instruction[1:0]];
        alu_b = imm8;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_REREADZ: begin
        alu_a = dc_vals[instruction[1:0]];
        alu_b = top;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_ADD: begin
        alu_a = second;
        alu_b = top;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b1;
        store_overflow = 1'b1;
      end
      `I_SUB: begin
        alu_a = second;
        alu_b = ~top;
        alu_ic = 1'b1;
        alu_opcode = `OP_ADD;
        store_carry = 1'b1;
        store_overflow = 1'b1;
      end
      `I_LSL: begin
        alu_a = second;
        alu_b = top;
        alu_ic = 1'bx;
        alu_opcode = `OP_LSL;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_LSR: begin
        alu_a = second;
        alu_b = top;
        alu_ic = 1'bx;
        alu_opcode = `OP_LSR;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_CSL: begin
        alu_a = second;
        alu_b = top;
        alu_ic = 1'bx;
        alu_opcode = `OP_CSL;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_CSR: begin
        alu_a = second;
        alu_b = top;
        alu_ic = 1'bx;
        alu_opcode = `OP_CSR;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_ASR: begin
        alu_a = second;
        alu_b = top;
        alu_ic = 1'bx;
        alu_opcode = `OP_ASR;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_AND: begin
        alu_a = second;
        alu_b = top;
        alu_ic = 1'bx;
        alu_opcode = `OP_AND;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_REWRITEZ: begin
        alu_a = dc_vals[instruction[1:0]];
        alu_b = top;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_RAWRITEZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_b = top;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BEQ: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BNE: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BLES: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BLEQ: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BLESU: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BLEQU: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_ADDI: begin
        alu_a = imm;
        alu_b = top;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b1;
        store_overflow = 1'b1;
      end
      `I_ADDI8: begin
        alu_a = simm8;
        alu_b = top;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b1;
        store_overflow = 1'b1;
      end
      `I_ADDI16: begin
        alu_a = simm16;
        alu_b = top;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b1;
        store_overflow = 1'b1;
      end
      `I_SUBI: begin
        alu_a = imm;
        alu_b = ~top;
        alu_ic = 1'b1;
        alu_opcode = `OP_ADD;
        store_carry = 1'b1;
        store_overflow = 1'b1;
      end
      `I_LSLI: begin
        alu_a = top;
        alu_b = imm8[7] ? -simm8 : imm8;
        alu_ic = 1'bx;
        alu_opcode = imm8[7] ? `OP_LSR : `OP_LSL;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_CSLI: begin
        alu_a = top;
        alu_b = simm8;
        alu_ic = 1'bx;
        alu_opcode = `OP_CSL;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_ASRI: begin
        alu_a = top;
        alu_b = imm8;
        alu_ic = 1'bx;
        alu_opcode = `OP_ASR;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_ANDI: begin
        alu_a = top;
        alu_b = imm;
        alu_ic = 1'bx;
        alu_opcode = `OP_AND;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_ORI: begin
        alu_a = top;
        alu_b = imm;
        alu_ic = 1'bx;
        alu_opcode = `OP_OR;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_XORI: begin
        alu_a = top;
        alu_b = imm;
        alu_ic = 1'bx;
        alu_opcode = `OP_XOR;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BC: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BNC: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BO: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BNO: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BI: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BNI: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_INDEXZ: begin
        alu_a = dcs[instruction[1:0]];
        alu_b = imm8;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_OR: begin
        alu_a = second;
        alu_b = top;
        alu_ic = 1'bx;
        alu_opcode = `OP_OR;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_XOR: begin
        alu_a = second;
        alu_b = top;
        alu_ic = 1'bx;
        alu_opcode = `OP_XOR;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_LOOP: begin
        alu_a = pc_advance;
        alu_b = imm16;
        alu_ic = 1'b1;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BZ: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BNZ: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_WRITEPRI: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BA: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_BNA: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_WRITEPORI: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      `I_WRITEPSRI: begin
        alu_a = pc;
        alu_b = simm16;
        alu_ic = 1'b0;
        alu_opcode = `OP_ADD;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
      default: begin
        alu_a = {WORD_WIDTH{1'bx}};
        alu_b = {WORD_WIDTH{1'bx}};
        alu_ic = 1'bx;
        alu_opcode = `OP_NOP;
        store_carry = 1'b0;
        store_overflow = 1'b0;
      end
    endcase
  end
endmodule
