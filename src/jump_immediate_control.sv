`include "../src/instructions.sv"

module jump_immediate_control(
  instruction,
  top,
  second,
  carry,
  overflow,
  interrupt,
  jump_immediate
);
  parameter WORD_WIDTH = 32;

  input [7:0] instruction;
  input [WORD_WIDTH-1:0] top, second;
  input carry, overflow, interrupt;
  output reg jump_immediate;

  always @* begin
    case (instruction)
      `I_CALLI: jump_immediate = 1;
      `I_JMPI: jump_immediate = 1;
      `I_JC: jump_immediate = carry;
      `I_JNC: jump_immediate = ~carry;
      `I_JO: jump_immediate = overflow;
      `I_JNO: jump_immediate = ~overflow;
      `I_JI: jump_immediate = interrupt;
      `I_JNI: jump_immediate = ~interrupt;
      `I_JEQ: jump_immediate = second == top;
      `I_JNE: jump_immediate = second != top;
      `I_LES: jump_immediate = $signed(second) < $signed(top);
      `I_LEQ: jump_immediate = $signed(second) <= $signed(top);
      `I_LESU: jump_immediate = second < top;
      `I_LEQU: jump_immediate = second <= top;
      default: jump_immediate = 0;
    endcase
  end
endmodule
