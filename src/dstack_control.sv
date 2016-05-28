`include "../src/instructions.sv"

module dstack_control(
  instruction,
  top,
  second,
  third,
  alu_out,
  mem_in,
  memload_last,
  receiver_self_permissions,
  receiver_self_addresses,
  conveyor_access,
  movement,
  next_top,
);
  parameter WORD_WIDTH = 32;
  parameter TOTAL_BUSES = 1;
  parameter CONVEYOR_WIDTH = WORD_WIDTH;

  input [7:0] instruction;
  input [WORD_WIDTH-1:0] top, second, third, alu_out, mem_in;
  input memload_last;
  input [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_self_permissions;
  input [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_self_addresses;
  input [CONVEYOR_WIDTH-1:0] conveyor_access;
  output reg [1:0] movement;
  output reg [WORD_WIDTH-1:0] next_top;

  always @* begin
    movement = instruction[6:5];
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
      `I_CVZ: next_top = conveyor_access[WORD_WIDTH-1:0];
      default: next_top = {WORD_WIDTH{1'bx}};
    endcase
  end
endmodule
