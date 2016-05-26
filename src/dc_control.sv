`include "../src/instructions.sv"

module dc_control(
  instruction,
  jump_immediate,
  advance_read,
  advance_write,
  set,
  set_direction,
  choice,
);
  input [7:0] instruction;
  input jump_immediate;
  output reg advance_read, advance_write;
  output reg set;
  output reg set_direction;
  output reg [1:0] choice;

  always @* begin
    casez (instruction)
      `I_ADDZ: begin
        advance_read = 1;
        advance_write = 0;
        set = 0;
        set_direction = 1'bx;
        choice = instruction[1:0];
      end
      `I_READZ: begin
        advance_read = 1;
        advance_write = 0;
        set = 0;
        set_direction = 1'bx;
        choice = instruction[1:0];
      end
      `I_WRITEZ: begin
        advance_read = 0;
        advance_write = 1;
        set = 0;
        set_direction = 1'bx;
        choice = instruction[1:0];
      end
      `I_SETFZ: begin
        advance_read = 0;
        advance_write = 0;
        set = 1;
        set_direction = 0;
        choice = instruction[1:0];
      end
      `I_SETBZ: begin
        advance_read = 0;
        advance_write = 0;
        set = 1;
        set_direction = 1;
        choice = instruction[1:0];
      end
      default: begin
        if (jump_immediate) begin
          advance_read = 1;
          advance_write = 0;
          set = 0;
          set_direction = 1'bx;
          choice = 0;
        end else begin
          advance_read = 0;
          advance_write = 0;
          set = 0;
          set_direction = 1'bx;
          choice = 2'bx;
        end
      end
    endcase
  end
endmodule
