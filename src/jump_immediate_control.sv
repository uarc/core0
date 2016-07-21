`include "../src/instructions.sv"

module jump_immediate_control(
  instruction,
  top,
  second,
  carry,
  overflow,
  interrupt,
  jump_immediate,
  branch
);
  parameter WORD_WIDTH = 32;

  input [7:0] instruction;
  input [WORD_WIDTH-1:0] top, second;
  input carry, overflow, interrupt;
  output reg jump_immediate;
  output reg branch;

  always @* begin
    case (instruction)
      `I_CALLI: begin
        jump_immediate = 1'b1;
        branch = 1'b0;
      end
      `I_JMPI: begin
        jump_immediate = 1'b1;
        branch = 1'b0;
      end
      `I_JC: begin
        jump_immediate = carry;
        branch = 1'b1;
      end
      `I_JNC: begin
        jump_immediate = ~carry;
        branch = 1'b1;
      end
      `I_JO: begin
        jump_immediate = overflow;
        branch = 1'b1;
      end
      `I_JNO: begin
        jump_immediate = ~overflow;
        branch = 1'b1;
      end
      `I_JI: begin
        jump_immediate = interrupt;
        branch = 1'b1;
      end
      `I_JNI: begin
        jump_immediate = ~interrupt;
        branch = 1'b1;
      end
      `I_JEQ: begin
        jump_immediate = second == top;
        branch = 1'b1;
      end
      `I_JNE: begin
        jump_immediate = second != top;
        branch = 1'b1;
      end
      `I_LES: begin
        jump_immediate = $signed(second) < $signed(top);
        branch = 1'b1;
      end
      `I_LEQ: begin
        jump_immediate = $signed(second) <= $signed(top);
        branch = 1'b1;
      end
      `I_LESU: begin
        jump_immediate = second < top;
        branch = 1'b1;
      end
      `I_LEQU: begin
        jump_immediate = second <= top;
        branch = 1'b1;
      end
      default: begin
        jump_immediate = 1'b0;
        branch = 1'b0;
      end
    endcase
  end
endmodule
