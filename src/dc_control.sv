`include "../src/instructions.sv"

module dc_control(
  instruction,
  jump_immediate,
  top,
  dcs,
  dc_directions,
  dc_modifies,
  dc_nexts,
  dc_next_directions,
  dc_next_modifies,
  write_out,
  write_address,
  reload,
  choice
);
  parameter MAIN_ADDR_WIDTH = 1;

  input [7:0] instruction;
  input jump_immediate;
  input [MAIN_ADDR_WIDTH-1:0] top;
  input [3:0][MAIN_ADDR_WIDTH-1:0] dcs;
  input [3:0] dc_directions;
  input [3:0] dc_modifies;
  output reg [3:0][MAIN_ADDR_WIDTH-1:0] dc_nexts;
  output reg [3:0] dc_next_directions;
  output reg [3:0] dc_next_modifies;
  output reg write_out;
  output reg [MAIN_ADDR_WIDTH-1:0] write_address;
  output reg reload;
  output reg [1:0] choice;

  wire [3:0][MAIN_ADDR_WIDTH-1:0] dc_read_advances;
  wire [3:0][MAIN_ADDR_WIDTH-1:0] dc_write_advances;

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin : DC_CONTROL_ADVANCE_LOOP
      assign dc_read_advances[i] = dcs[i] + 1;
      assign dc_write_advances[i] = dc_directions[i] ? dcs[i] - 1 : dcs[i] + 1;
    end
  endgenerate

  always @* begin
    casez (instruction)
      `I_ADDZ: begin
        choice = instruction[1:0];
        dc_next_directions = dc_directions;
        dc_next_modifies = dc_modifies;
        for (int i = 0; i < 4; i++) begin
          if (i == choice)
            dc_nexts[i] = dc_read_advances[i];
          else
            dc_nexts[i] = dcs[i];
        end
        reload = 1;
        write_out = 0;
        write_address = {MAIN_ADDR_WIDTH{1'bx}};
      end
      `I_READZ: begin
        choice = instruction[1:0];
        dc_next_directions = dc_directions;
        dc_next_modifies = dc_modifies;
        for (int i = 0; i < 4; i++) begin
          if (i == choice)
            dc_nexts[i] = dc_read_advances[i];
          else
            dc_nexts[i] = dcs[i];
        end
        reload = 1;
        write_out = 0;
        write_address = {MAIN_ADDR_WIDTH{1'bx}};
      end
      `I_WRITEZ: begin
        choice = instruction[1:0];
        dc_next_directions = dc_directions;
        dc_next_modifies = dc_modifies;
        for (int i = 0; i < 4; i++) begin
          if (i == choice)
            dc_nexts[i] = dc_write_advances[i];
          else
            dc_nexts[i] = dcs[i];
        end
        reload = 1;
        write_out = 1;
        write_address = dc_directions[choice] ? dc_write_advances[choice] : dcs[choice];
      end
      `I_SETFZ: begin
        choice = instruction[1:0];
        dc_next_directions = dc_directions & ~(1 << choice);
        dc_next_modifies = dc_modifies | (1 << choice);
        for (int i = 0; i < 4; i++) begin
          if (i == choice)
            dc_nexts[i] = top;
          else
            dc_nexts[i] = dcs[i];
        end
        reload = 1;
        write_out = 0;
        write_address = {MAIN_ADDR_WIDTH{1'bx}};
      end
      `I_SETBZ: begin
        choice = instruction[1:0];
        dc_next_directions = dc_directions | (1 << choice);
        dc_next_modifies = dc_modifies | (1 << choice);
        for (int i = 0; i < 4; i++) begin
          if (i == choice)
            dc_nexts[i] = top;
          else
            dc_nexts[i] = dcs[i];
        end
        reload = 1;
        write_out = 0;
        write_address = {MAIN_ADDR_WIDTH{1'bx}};
      end
      `I_LOOPI: begin
        choice = 0;
        dc_next_directions = dc_directions;
        dc_next_modifies = dc_modifies;
        dc_nexts[0] = dc_read_advances[0];
        dc_nexts[3:1] = dcs[3:1];
        reload = 1;
        write_out = 0;
        write_address = {MAIN_ADDR_WIDTH{1'bx}};
      end
      default: begin
        if (jump_immediate) begin
          choice = 0;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts[0] = dc_read_advances[0];
          dc_nexts[3:1] = dcs[3:1];
          reload = 1;
          write_out = 0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
        end else begin
          choice = 2'bx;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          reload = 0;
          write_out = 0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
        end
      end
    endcase
  end
endmodule
