`include "../src/instructions.sv"

module flow_control(
  instruction,
  top,
  second,
  carry,
  overflow,
  interrupt,
  jump,
  branch
);
  parameter WORD_WIDTH = 32;

  input [7:0] instruction;
  input [WORD_WIDTH-1:0] top, second;
  input carry, overflow, interrupt;
  output reg branch;
  output reg jump;

  always @* begin
    case (instruction)
      `I_CALLI: begin
        branch = 1'b0;
        jump = 1'b1;
      end
      `I_JMPI: begin
        branch = 1'b0;
        jump = 1'b1;
      end
      `I_BRA: begin
        branch = 1'b1;
        jump = 1'b0;
      end
      `I_BC: begin
        branch = carry;
        jump = 1'b0;
      end
      `I_BNC: begin
        branch = ~carry;
        jump = 1'b0;
      end
      `I_BO: begin
        branch = overflow;
        jump = 1'b0;
      end
      `I_BNO: begin
        branch = ~overflow;
        jump = 1'b0;
      end
      `I_BI: begin
        branch = interrupt;
        jump = 1'b0;
      end
      `I_BNI: begin
        branch = ~interrupt;
        jump = 1'b0;
      end
      `I_BEQ: begin
        branch = second == top;
        jump = 1'b0;
      end
      `I_BNE: begin
        branch = second != top;
        jump = 1'b0;
      end
      `I_BLES: begin
        branch = $signed(second) < $signed(top);
        jump = 1'b0;
      end
      `I_BLEQ: begin
        branch = $signed(second) <= $signed(top);
        jump = 1'b0;
      end
      `I_BLESU: begin
        branch = second < top;
        jump = 1'b0;
      end
      `I_BLEQU: begin
        branch = second <= top;
        jump = 1'b0;
      end
      `I_BZ: begin
        branch = top == {WORD_WIDTH{1'b0}};
        jump = 1'b0;
      end
      `I_BNZ: begin
        branch = top != {WORD_WIDTH{1'b0}};
        jump = 1'b0;
      end
      default: begin
        branch = 1'b0;
        jump = 1'b0;
      end
    endcase
  end
endmodule
