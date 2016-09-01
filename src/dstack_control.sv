`include "../src/instructions.sv"

module dstack_control(
  instruction,
  imm,
  halt,
  dcs,
  dc_vals,
  iterators,
  top,
  second,
  third,
  alu_out,
  mem_in,
  self_perimission,
  self_address,
  receiver_self_permissions,
  receiver_self_addresses,
  conveyor_value,
  rotate_value,
  movement,
  next_top,
  rotate,
  rotate_addr
);
  parameter WORD_WIDTH = 32;
  parameter TOTAL_BUSES = 1;

  input [7:0] instruction;
  input [WORD_WIDTH-1:0] imm;
  input halt;
  input [3:0][WORD_WIDTH-1:0] dcs, dc_vals, iterators;
  input [WORD_WIDTH-1:0] top, second, third, alu_out, mem_in;
  input [WORD_WIDTH-1:0] self_perimission, self_address;
  input [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_self_permissions, receiver_self_addresses;
  input [WORD_WIDTH-1:0] conveyor_value, rotate_value;
  output reg [1:0] movement;
  output reg [WORD_WIDTH-1:0] next_top;
  output reg rotate;
  output reg [4:0] rotate_addr;

  wire [WORD_WIDTH-1:0] imm8, imm16;
  assign imm8 = {{(WORD_WIDTH-8){imm[7]}}, imm[7:0]};
  assign imm16 = {{(WORD_WIDTH-16){imm[15]}}, imm[15:0]};

  always @* begin
    if (halt) begin
      movement = 2'b00;
      rotate = 1'b0;
      rotate_addr = 5'bx;
      next_top = top;
    end else begin
      if (instruction[7]) begin
        if (instruction[6]) begin
          // copy
          if (instruction[5]) begin
            movement = 2'b01;
            rotate = 1'b0;
            rotate_addr = instruction[4:0];
          // rotate
          end else begin
            movement = 2'b00;
            rotate = 1'b1;
            rotate_addr = instruction[4:0];
          end
        end else begin
          if (instruction[5:4] == 2'b11) begin
            if (instruction[3]) begin
              movement = 2'b10;
              rotate = 1'b0;
              rotate_addr = 5'bx;
            end else begin
              movement = 2'b00;
              rotate = 1'b0;
              rotate_addr = 5'bx;
            end
          end else begin
            movement = instruction[5:4];
            rotate = 1'b0;
            rotate_addr = 5'bx;
          end
        end
      end else begin
        movement = instruction[6:5];
        rotate = 1'b0;
        rotate_addr = 5'bx;
      end
      casez (instruction)
        `I_MOVEZ: next_top = top;
        `I_RAREADZ: next_top = mem_in;
        `I_REREADIZ: next_top = mem_in;
        `I_INC: next_top = alu_out;
        `I_DEC: next_top = alu_out;
        `I_CARRY: next_top = alu_out;
        `I_BORROW: next_top = alu_out;
        `I_INV: next_top = alu_out;
        `I_BREAK: next_top = top;
        `I_RETURN: next_top = top;
        `I_CONTINUE: next_top = top;
        `I_INTEN: next_top = top;
        `I_INTRECV: next_top = top;
        `I_ILOOP: next_top = top;
        `I_KILL: next_top = top;
        `I_INTWAIT: next_top = top;
        `I_GETBP: next_top = receiver_self_permissions[top];
        `I_GETBA: next_top = receiver_self_addresses[top];
        `I_CALLI: next_top = top;
        `I_JMPI: next_top = top;
        `I_BRA: next_top = top;
        `I_DISCARD: next_top = top;
        `I_CALLRI: next_top = top;
        `I_CVZ: next_top = conveyor_value;
        `I_READZ: next_top = dc_vals[instruction[1:0]];
        `I_RAREADIZ: next_top = mem_in;
        `I_GETZ: next_top = dcs[instruction[1:0]];
        `I_IZ: next_top = iterators[instruction[1:0]];
        `I_WRITEPREZ: next_top = second;
        `I_WRITEPSTZ: next_top = second;
        `I_SETZ: next_top = second;
        `I_RAWRITEIZ: next_top = second;
        `I_REWRITEIZ: next_top = second;
        `I_REREADZ: next_top = second;
        `I_ADD: next_top = alu_out;
        `I_SUB: next_top = alu_out;
        `I_LSL: next_top = alu_out;
        `I_LSR: next_top = alu_out;
        `I_CSL: next_top = alu_out;
        `I_CSR: next_top = alu_out;
        `I_ASR: next_top = alu_out;
        `I_AND: next_top = alu_out;
        `I_REWRITEZ: next_top = third;
        `I_RAWRITEZ: next_top = third;
        `I_WRITE: next_top = third;
        `I_WRITEP: next_top = third;
        `I_WRITEPO: next_top = third;
        `I_WRITEPS: next_top = third;
        `I_BEQ: next_top = third;
        `I_BNE: next_top = third;
        `I_BLES: next_top = third;
        `I_BLEQ: next_top = third;
        `I_BLESU: next_top = third;
        `I_BLEQU: next_top = third;
        `I_RECV: next_top = third;
        `I_SEND: next_top = third;
        `I_INCEPT: next_top = third;
        `I_SET: next_top = third;
        `I_SEL: next_top = third;
        `I_SETPA: next_top = third;
        `I_EXPECT: next_top = third;
        `I_SEF: next_top = third;
        `I_RESET: next_top = {WORD_WIDTH{1'bx}};
        `I_DDROP: next_top = third;
        `I_ADDI: next_top = alu_out;
        `I_ADDI8: next_top = alu_out;
        `I_ADDI16: next_top = alu_out;
        `I_SUBI: next_top = alu_out;
        `I_LSLI: next_top = alu_out;
        `I_CSLI: next_top = alu_out;
        `I_ASRI: next_top = alu_out;
        `I_ANDI: next_top = alu_out;
        `I_ORI: next_top = alu_out;
        `I_XORI: next_top = alu_out;
        `I_BC: next_top = top;
        `I_BNC: next_top = top;
        `I_BO: next_top = top;
        `I_BNO: next_top = top;
        `I_BI: next_top = top;
        `I_BNI: next_top = top;
        `I_INDEXZ: next_top = alu_out;
        `I_IMM8: next_top = imm8;
        `I_IMM16: next_top = imm16;
        `I_IMM32: next_top = imm;
        // TODO: Handle I_IMM64 in the case we are synthesizing u0-64
        `I_GETP: next_top = self_perimission;
        `I_GETA: next_top = self_address;
        `I_OR: next_top = alu_out;
        `I_XOR: next_top = alu_out;
        `I_READ: next_top = second;
        `I_CALL: next_top = second;
        `I_JMP: next_top = second;
        `I_INTSET: next_top = second;
        `I_SEB: next_top = second;
        `I_SLB: next_top = second;
        `I_USB: next_top = second;
        `I_INTSEND: next_top = second;
        `I_LOOP: next_top = second;
        `I_BZ: next_top = second;
        `I_BNZ: next_top = second;
        `I_WRITEPI: next_top = second;
        `I_WRITEPRI: next_top = second;
        `I_DROP: next_top = second;
        `I_PUSHZ: next_top = top;
        `I_POPZ: next_top = top;
        `I_BA: next_top = second;
        `I_BNA: next_top = second;
        `I_WRITEPORI: next_top = second;
        `I_WRITEPSRI: next_top = second;
        `I_ROTZ: next_top = rotate_value;
        `I_COPYZ: next_top = rotate_value;
        default: next_top = {WORD_WIDTH{1'bx}};
      endcase
    end
  end
endmodule
