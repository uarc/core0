`include "../src/instructions.sv"

module pc_control(
  instruction,
  pc,
  pc_advance
);
  parameter WORD_WIDTH = 32;
  parameter PROGRAM_ADDR_WIDTH = 1;

  input [7:0] instruction;
  input [PROGRAM_ADDR_WIDTH-1:0] pc;
  output reg [PROGRAM_ADDR_WIDTH-1:0] pc_advance;

  wire [PROGRAM_ADDR_WIDTH-1:0] pc_advance_imm0, pc_advance_imm8, pc_advance_imm16,
    pc_advance_imm32, pc_advance_immword;

  assign pc_advance_imm0 = pc + 1;
  assign pc_advance_imm8 = pc + 2;
  assign pc_advance_imm16 = pc + 3;
  assign pc_advance_imm32 = pc + 5;
  assign pc_advance_immword = pc + 1 + WORD_WIDTH / 8;

  always @* begin
    casez (instruction)
      `I_MOVEZ: pc_advance = pc_advance_imm8;
      `I_RAREADZ: pc_advance = pc_advance_imm0;
      `I_REREADIZ: pc_advance = pc_advance_imm8;
      `I_INC: pc_advance = pc_advance_imm0;
      `I_DEC: pc_advance = pc_advance_imm0;
      `I_CARRY: pc_advance = pc_advance_imm0;
      `I_BORROW: pc_advance = pc_advance_imm0;
      `I_INV: pc_advance = pc_advance_imm0;
      `I_BREAK: pc_advance = pc_advance_imm0;
      `I_RETURN: pc_advance = pc_advance_imm0;
      `I_CONTINUE: pc_advance = pc_advance_imm0;
      `I_INTEN: pc_advance = pc_advance_imm0;
      `I_INTRECV: pc_advance = pc_advance_imm0;
      `I_ILOOP: pc_advance = pc_advance_imm16;
      `I_KILL: pc_advance = pc_advance_imm0;
      `I_INTWAIT: pc_advance = pc_advance_imm0;
      `I_GETBP: pc_advance = pc_advance_imm0;
      `I_GETBA: pc_advance = pc_advance_imm0;
      `I_CALLI: pc_advance = pc_advance_immword;
      `I_JMPI: pc_advance = pc_advance_immword;
      `I_BRA: pc_advance = pc_advance_imm16;
      `I_DISCARD: pc_advance = pc_advance_imm0;
      `I_CALLRI: pc_advance = pc_advance_imm16;
      `I_CVZ: pc_advance = pc_advance_imm0;
      `I_READZ: pc_advance = pc_advance_imm8;
      `I_RAREADIZ: pc_advance = pc_advance_imm8;
      `I_GETZ: pc_advance = pc_advance_imm0;
      `I_IZ: pc_advance = pc_advance_imm0;
      `I_WRITEPREZ: pc_advance = pc_advance_imm8;
      `I_WRITEPSTZ: pc_advance = pc_advance_imm8;
      `I_SETZ: pc_advance = pc_advance_imm0;
      `I_RAWRITEIZ: pc_advance = pc_advance_imm8;
      `I_REWRITEIZ: pc_advance = pc_advance_imm8;
      `I_REREADZ: pc_advance = pc_advance_imm0;
      `I_ADD: pc_advance = pc_advance_imm0;
      `I_SUB: pc_advance = pc_advance_imm0;
      `I_LSL: pc_advance = pc_advance_imm0;
      `I_LSR: pc_advance = pc_advance_imm0;
      `I_CSL: pc_advance = pc_advance_imm0;
      `I_CSR: pc_advance = pc_advance_imm0;
      `I_ASR: pc_advance = pc_advance_imm0;
      `I_AND: pc_advance = pc_advance_imm0;
      `I_REWRITEZ: pc_advance = pc_advance_imm0;
      `I_RAWRITEZ: pc_advance = pc_advance_imm0;
      `I_WRITE: pc_advance = pc_advance_imm0;
      `I_WRITEP: pc_advance = pc_advance_imm0;
      `I_WRITEPO: pc_advance = pc_advance_imm0;
      `I_WRITEPS: pc_advance = pc_advance_imm0;
      `I_BEQ: pc_advance = pc_advance_imm16;
      `I_BNE: pc_advance = pc_advance_imm16;
      `I_BLES: pc_advance = pc_advance_imm16;
      `I_BLEQ: pc_advance = pc_advance_imm16;
      `I_BLESU: pc_advance = pc_advance_imm16;
      `I_BLEQU: pc_advance = pc_advance_imm16;
      `I_RECV: pc_advance = pc_advance_imm0;
      `I_SEND: pc_advance = pc_advance_imm0;
      `I_INCEPT: pc_advance = pc_advance_imm0;
      `I_SET: pc_advance = pc_advance_imm0;
      `I_SEL: pc_advance = pc_advance_imm0;
      `I_SETPA: pc_advance = pc_advance_imm0;
      `I_EXPECT: pc_advance = pc_advance_imm0;
      `I_SEF: pc_advance = pc_advance_imm0;
      `I_RESET: pc_advance = pc_advance_imm0;
      `I_DDROP: pc_advance = pc_advance_imm0;
      `I_SENDP: pc_advance = pc_advance_imm0;
      `I_INCEPTP: pc_advance = pc_advance_imm0;
      `I_ADDI: pc_advance = pc_advance_immword;
      `I_ADDI8: pc_advance = pc_advance_imm8;
      `I_ADDI16: pc_advance = pc_advance_imm16;
      `I_SUBI: pc_advance = pc_advance_immword;
      `I_LSLI: pc_advance = pc_advance_imm8;
      `I_CSLI: pc_advance = pc_advance_imm8;
      `I_ASRI: pc_advance = pc_advance_imm8;
      `I_ANDI: pc_advance = pc_advance_immword;
      `I_ORI: pc_advance = pc_advance_immword;
      `I_XORI: pc_advance = pc_advance_immword;
      `I_BC: pc_advance = pc_advance_imm16;
      `I_BNC: pc_advance = pc_advance_imm16;
      `I_BO: pc_advance = pc_advance_imm16;
      `I_BNO: pc_advance = pc_advance_imm16;
      `I_BI: pc_advance = pc_advance_imm16;
      `I_BNI: pc_advance = pc_advance_imm16;
      `I_INDEXZ: pc_advance = pc_advance_imm8;
      `I_IMM8: pc_advance = pc_advance_imm8;
      `I_IMM16: pc_advance = pc_advance_imm16;
      `I_IMM32: pc_advance = pc_advance_imm32;
      // TODO: Handle u0-64 64-bit immediate load.
      `I_GETP: pc_advance = pc_advance_imm0;
      `I_GETA: pc_advance = pc_advance_imm0;
      `I_OR: pc_advance = pc_advance_imm0;
      `I_XOR: pc_advance = pc_advance_imm0;
      `I_READ: pc_advance = pc_advance_imm0;
      `I_CALL: pc_advance = pc_advance_imm0;
      `I_JMP: pc_advance = pc_advance_imm0;
      `I_INTSET: pc_advance = pc_advance_imm0;
      `I_SEB: pc_advance = pc_advance_imm0;
      `I_SLB: pc_advance = pc_advance_imm0;
      `I_USB: pc_advance = pc_advance_imm0;
      `I_INTSEND: pc_advance = pc_advance_imm0;
      `I_LOOP: pc_advance = pc_advance_imm16;
      `I_BZ: pc_advance = pc_advance_imm16;
      `I_BNZ: pc_advance = pc_advance_imm16;
      `I_WRITEPI: pc_advance = pc_advance_immword;
      `I_WRITEPRI: pc_advance = pc_advance_imm16;
      `I_DROP: pc_advance = pc_advance_imm0;
      `I_PUSHZ: pc_advance = pc_advance_imm0;
      `I_POPZ: pc_advance = pc_advance_imm0;
      `I_BA: pc_advance = pc_advance_imm16;
      `I_BNA: pc_advance = pc_advance_imm16;
      `I_WRITEPORI: pc_advance = pc_advance_imm16;
      `I_WRITEPSRI: pc_advance = pc_advance_imm16;
      `I_ROTZ: pc_advance = pc_advance_imm0;
      `I_COPYZ: pc_advance = pc_advance_imm0;
      default: pc_advance = pc_advance_imm0;
    endcase
  end
endmodule
