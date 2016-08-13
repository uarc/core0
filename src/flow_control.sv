`include "../src/instructions.sv"

module flow_control(
  instruction,
  top,
  second,
  lstack_dontloop,
  carry,
  overflow,
  interrupt,
  receiver_sends,
  jump_immediate,
  jump_stack,
  branch
);
  parameter WORD_WIDTH = 32;
  parameter TOTAL_BUSES = 1;

  input [7:0] instruction;
  input [WORD_WIDTH-1:0] top, second;
  input lstack_dontloop;
  input carry, overflow, interrupt;
  input [TOTAL_BUSES-1:0] receiver_sends;
  output reg jump_immediate, jump_stack;
  output reg branch;

  always @* begin
    case (instruction)
      `I_CALLI: begin
        branch = 1'b0;
        jump_immediate = 1'b1;
        jump_stack = 1'b0;
      end
      `I_JMPI: begin
        branch = 1'b0;
        jump_immediate = 1'b1;
        jump_stack = 1'b0;
      end
      `I_BRA: begin
        branch = 1'b1;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_CALLRI: begin
        branch = 1'b1;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BC: begin
        branch = carry;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BNC: begin
        branch = ~carry;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BO: begin
        branch = overflow;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BNO: begin
        branch = ~overflow;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BI: begin
        branch = interrupt;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BNI: begin
        branch = ~interrupt;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BEQ: begin
        branch = second == top;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BNE: begin
        branch = second != top;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BLES: begin
        branch = $signed(second) < $signed(top);
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BLEQ: begin
        branch = $signed(second) <= $signed(top);
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BLESU: begin
        branch = second < top;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BLEQU: begin
        branch = second <= top;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_CALL: begin
        branch = 1'b0;
        jump_immediate = 1'b0;
        jump_stack = 1'b1;
      end
      `I_JMP: begin
        branch = 1'b0;
        jump_immediate = 1'b0;
        jump_stack = 1'b1;
      end
      `I_LOOP: begin
        branch = lstack_dontloop;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BZ: begin
        branch = top == {WORD_WIDTH{1'b0}};
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BNZ: begin
        branch = top != {WORD_WIDTH{1'b0}};
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BA: begin
        branch = receiver_sends[top];
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      `I_BNA: begin
        branch = !receiver_sends[top];
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
      default: begin
        branch = 1'b0;
        jump_immediate = 1'b0;
        jump_stack = 1'b0;
      end
    endcase
  end
endmodule
