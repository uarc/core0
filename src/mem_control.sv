`include "../src/instructions.sv"

module mem_control(
  instruction,
  jump_immediate,
  top,
  second,
  alu_out,
  stream_in,
  stream_in_value,
  stream_out,
  stream_address,
  conveyor_memload_last,
  dstack_memload_last,
  dcs,
  dc_directions,
  dc_modifies,
  dc_nexts,
  dc_next_directions,
  dc_next_modifies,
  write_out,
  write_address,
  write_value,
  read_address,
  conveyor_memload,
  dstack_memload,
  reload,
  choice
);
  parameter MAIN_ADDR_WIDTH = 1;
  parameter WORD_WIDTH = 32;

  input [7:0] instruction;
  input jump_immediate;
  input [WORD_WIDTH-1:0] top;
  input [WORD_WIDTH-1:0] second;
  input [MAIN_ADDR_WIDTH-1:0] alu_out;
  input stream_in, stream_out;
  input [WORD_WIDTH-1:0] stream_in_value;
  input [MAIN_ADDR_WIDTH-1:0] stream_address;
  input conveyor_memload_last, dstack_memload_last;
  input [3:0][MAIN_ADDR_WIDTH-1:0] dcs;
  input [3:0] dc_directions;
  input [3:0] dc_modifies;
  output reg [3:0][MAIN_ADDR_WIDTH-1:0] dc_nexts;
  output reg [3:0] dc_next_directions;
  output reg [3:0] dc_next_modifies;
  output reg write_out;
  output reg [MAIN_ADDR_WIDTH-1:0] write_address;
  output reg [WORD_WIDTH-1:0] write_value;
  output reg [MAIN_ADDR_WIDTH-1:0] read_address;
  output reg conveyor_memload, dstack_memload;
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
      `I_RREADZ: begin
        choice = 2'bx;
        dc_next_directions = dc_directions;
        dc_next_modifies = dc_modifies;
        dc_nexts = dcs;
        reload = 0;
        write_out = 0;
        write_address = {MAIN_ADDR_WIDTH{1'bx}};
        write_value = {WORD_WIDTH{1'bx}};
        read_address = alu_out;
        conveyor_memload = 0;
        dstack_memload = !dstack_memload_last;
      end
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
        write_value = {WORD_WIDTH{1'bx}};
        read_address = dc_read_advances[choice];
        conveyor_memload = 0;
        dstack_memload = 0;
      end
      `I_READS: begin
        choice = 2'bx;
        dc_next_directions = dc_directions;
        dc_next_modifies = dc_modifies;
        dc_nexts = dcs;
        reload = 0;
        write_out = 0;
        write_address = {MAIN_ADDR_WIDTH{1'bx}};
        write_value = {WORD_WIDTH{1'bx}};
        read_address = top;
        conveyor_memload = 0;
        dstack_memload = !dstack_memload_last;
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
        write_value = {WORD_WIDTH{1'bx}};
        read_address = dc_read_advances[choice];
        conveyor_memload = 0;
        dstack_memload = 0;
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
        write_value = top;
        read_address = dc_write_advances[choice];
        conveyor_memload = 0;
        dstack_memload = 0;
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
        write_value = {WORD_WIDTH{1'bx}};
        read_address = top;
        conveyor_memload = 0;
        dstack_memload = 0;
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
        write_value = {WORD_WIDTH{1'bx}};
        read_address = top;
        conveyor_memload = 0;
        dstack_memload = 0;
      end
      `I_RWRITEZ: begin
        choice = 2'bx;
        dc_next_directions = dc_directions;
        dc_next_modifies = dc_modifies;
        dc_nexts = dcs;
        reload = 0;
        write_out = 1;
        write_address = alu_out;
        write_value = second;
        read_address = {MAIN_ADDR_WIDTH{1'bx}};
        conveyor_memload = 0;
        dstack_memload = 0;
      end
      `I_WRITE: begin
        choice = 2'bx;
        dc_next_directions = dc_directions;
        dc_next_modifies = dc_modifies;
        dc_nexts = dcs;
        reload = 0;
        write_out = 1;
        write_address = top;
        write_value = second;
        read_address = {MAIN_ADDR_WIDTH{1'bx}};
        conveyor_memload = 0;
        dstack_memload = 0;
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
        write_value = {WORD_WIDTH{1'bx}};
        read_address = dc_read_advances[0];
        conveyor_memload = 0;
        dstack_memload = 0;
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
          write_value = {WORD_WIDTH{1'bx}};
          read_address = dc_read_advances[0];
          conveyor_memload = 0;
          dstack_memload = 0;
        end else if (stream_in) begin
          choice = 0;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          reload = 0;
          write_out = 1;
          write_address = stream_address;
          write_value = stream_in_value;
          read_address = {MAIN_ADDR_WIDTH{1'bx}};
          conveyor_memload = 0;
          dstack_memload = 0;
        end else if (stream_out) begin
          choice = 0;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          reload = 0;
          write_out = 0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = stream_address;
          conveyor_memload = 0;
          dstack_memload = 0;
        end else begin
          choice = 2'bx;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          reload = 0;
          write_out = 0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = {MAIN_ADDR_WIDTH{1'bx}};
          conveyor_memload = 0;
          dstack_memload = 0;
        end
      end
    endcase
  end
endmodule
