`include "../src/instructions.sv"

module dstack_control(
  instruction,
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
  input halt;
  input [3:0][WORD_WIDTH-1:0] dcs, dc_vals, iterators;
  input [WORD_WIDTH-1:0] top, second, third, alu_out, mem_in;
  input [WORD_WIDTH-1:0] self_perimission, self_address;
  input [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_self_permissions, receiver_self_addresses;
  input [WORD_WIDTH-1:0] conveyor_value, rotate_value;
  output reg [1:0] movement;
  output reg [WORD_WIDTH-1:0] next_top;
  output reg rotate;
  output reg [5:0] rotate_addr;

  always @* begin
    if (halt) begin
      movement = 2'b00;
      rotate = 0;
      rotate_addr = 5'bx;
    end else begin
      if (instruction[7] == 1'b1) begin
        // copy
        if (instruction[6] == 1'b1) begin
          movement = 2'b01;
          rotate = 0;
          rotate_addr = 5'bx;
        // rotate
        end else begin
          movement = 2'b00;
          rotate = 1;
          rotate_addr = instruction[5:0];
        end
      end else begin
        movement = instruction[6:5];
        rotate = 0;
        rotate_addr = 5'bx;
      end
    end

    casez (instruction)
      `I_RREADZ: next_top = mem_in;
      `I_ADDZ: next_top = alu_out;
      `I_INC: next_top = alu_out;
      `I_DEC: next_top = alu_out;
      `I_CARRY: next_top = alu_out;
      `I_BORROW: next_top = alu_out;
      `I_INV: next_top = alu_out;
      `I_BREAK: next_top = top;
      `I_READS: next_top = mem_in;
      `I_RET: next_top = top;
      `I_CONTINUE: next_top = top;
      `I_IEN: next_top = top;
      `I_RECV: next_top = top;
      `I_KILL: next_top = top;
      `I_WAIT: next_top = top;
      `I_GETBP: next_top = receiver_self_permissions[top];
      `I_GETBA: next_top = receiver_self_addresses[top];
      `I_CALLI: next_top = top;
      `I_JMPI: next_top = top;
      `I_JC: next_top = top;
      `I_JNC: next_top = top;
      `I_JO: next_top = top;
      `I_JNO: next_top = top;
      `I_JI: next_top = top;
      `I_JNI: next_top = top;
      `I_CVZ: next_top = conveyor_value;
      `I_READZ: next_top = dc_vals[instruction[1:0]];
      `I_GETZ: next_top = dcs[instruction[1:0]];
      `I_IZ: next_top = iterators[instruction[1:0]];
      `I_P0: next_top = 0;
      `I_DUP: next_top = top;
      `I_GETP: next_top = self_perimission;
      `I_GETA: next_top = self_address;
      `I_WRITEZ: next_top = second;
      `I_SETFZ: next_top = second;
      `I_SETBZ: next_top = second;
      `I_ADD: next_top = alu_out;
      `I_ADDC: next_top = alu_out;
      `I_SUB: next_top = alu_out;
      `I_SUBC: next_top = alu_out;
      `I_LSL: next_top = alu_out;
      `I_LSR: next_top = alu_out;
      `I_CSL: next_top = alu_out;
      `I_CSR: next_top = alu_out;
      `I_ASR: next_top = alu_out;
      `I_AND: next_top = alu_out;
      `I_OR: next_top = alu_out;
      `I_XOR: next_top = alu_out;
      `I_READA: next_top = second;
      `I_CALL: next_top = second;
      `I_JMP: next_top = second;
      `I_ISET: next_top = second;
      `I_SLB: next_top = second;
      `I_USB: next_top = second;
      `I_SEND: next_top = second;
      `I_LOOPI: next_top = second;
      `I_RWRITEZ: next_top = third;
      `I_WRITE: next_top = third;
      `I_JEQ: next_top = third;
      `I_JNE: next_top = third;
      `I_LES: next_top = third;
      `I_LEQ: next_top = third;
      `I_LESU: next_top = third;
      `I_LEQU: next_top = third;
      `I_IN: next_top = third;
      `I_OUT: next_top = third;
      `I_INCEPT: next_top = third;
      `I_SET: next_top = third;
      `I_SEL: next_top = third;
      `I_SETA: next_top = third;
      `I_LOOP: next_top = third;
      `I_SEF: next_top = third;
      `I_MUL: next_top = third;
      `I_MULU: next_top = third;
      `I_DIV: next_top = third;
      `I_DIVU: next_top = third;
      `I_ROTZ: next_top = rotate_value;
      default: next_top = {WORD_WIDTH{1'bx}};
    endcase
  end
endmodule
