`include "../src/instructions.sv"

module mem_control(
  reset,
  instruction,
  jump_immediate,
  top,
  second,
  alu_out,
  handle_interrupt,
  interrupt_dc0,
  stream_in,
  stream_in_value,
  stream_out,
  stream_address,
  conveyor_memload_last,
  dstack_memload_last,
  dcs,
  dc_val0,
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
  interrupt_memory_conflict,
  reload,
  choice
);
  parameter MAIN_ADDR_WIDTH = 1;
  parameter WORD_WIDTH = 32;

  input reset;
  input [7:0] instruction;
  input jump_immediate;
  input [WORD_WIDTH-1:0] top;
  input [WORD_WIDTH-1:0] second;
  input [MAIN_ADDR_WIDTH-1:0] alu_out;
  input handle_interrupt;
  input [MAIN_ADDR_WIDTH-1:0] interrupt_dc0;
  input stream_in, stream_out;
  input [WORD_WIDTH-1:0] stream_in_value;
  input [MAIN_ADDR_WIDTH-1:0] stream_address;
  input conveyor_memload_last, dstack_memload_last;
  input [3:0][MAIN_ADDR_WIDTH-1:0] dcs;
  input [WORD_WIDTH-1:0] dc_val0;
  input [3:0] dc_directions;
  input [3:0] dc_modifies;
  output reg [3:0][MAIN_ADDR_WIDTH-1:0] dc_nexts;
  output reg [3:0] dc_next_directions;
  output reg [3:0] dc_next_modifies;
  output reg write_out;
  output reg [MAIN_ADDR_WIDTH-1:0] write_address;
  output reg [WORD_WIDTH-1:0] write_value;
  output reg [MAIN_ADDR_WIDTH-1:0] read_address;
  output reg conveyor_memload, dstack_memload, interrupt_memory_conflict;
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
    if (reset) begin
      choice = 2'b0;
      dc_next_directions = 4'b0;
      dc_next_modifies = 4'b0;
      dc_nexts = {4{{MAIN_ADDR_WIDTH{1'b0}}}};
      reload = 1'b1;
      write_out = 1'b0;
      write_address = {MAIN_ADDR_WIDTH{1'bx}};
      write_value = {WORD_WIDTH{1'bx}};
      read_address = {MAIN_ADDR_WIDTH{1'b0}};
      conveyor_memload = 1'b0;
      dstack_memload = 1'b0;
    end else begin
      // We need special cases for when we are handling an interrupt (some instructions work fine)
      if (handle_interrupt) begin
        // Interrupts always reload dc0
        choice = 2'b0;
        // The system needs to effectively see what the next values would have been
        dc_next_directions = dc_directions;
        dc_next_modifies = dc_modifies;
        dc_nexts = dcs;
        // We always reload dc0
        reload = 1'b1;
        // We always read the new dc0 value
        read_address = interrupt_dc0;
        // Memloads are always 0
        conveyor_memload = 1'b0;
        dstack_memload = 1'b0;

        // Handle the few memory instructions (like writes) which can happen simultaneously with an interrupt
        casez (instruction)
          `I_RWRITEZ: begin
            interrupt_memory_conflict = 1'b0;
            write_out = 1'b1;
            write_address = alu_out;
            write_value = second;
          end
          `I_WRITE: begin
            interrupt_memory_conflict = 1'b0;
            write_out = 1'b1;
            write_address = top;
            write_value = second;
          end
          default: begin
            interrupt_memory_conflict =
              instruction == `I_RREADZ ||
              instruction == `I_ADDZ ||
              instruction == `I_LD0I ||
              instruction == `I_READS ||
              instruction == `I_READZ ||
              instruction == `I_WRITEZ ||
              instruction == `I_SETFZ ||
              instruction == `I_SETBZ ||
              instruction == `I_READA ||
              instruction == `I_ISET ||
              instruction == `I_LOOPI;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
          end
        endcase
      // When not handling an interrupt we can proceed as normal
      end else begin
        // Never a memory conflict then
        interrupt_memory_conflict = 1'b0;
        casez (instruction)
          `I_RREADZ: begin
            choice = 2'bx;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            reload = 1'b0;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = alu_out;
            conveyor_memload = 1'b0;
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
            reload = 1'b1;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = dc_read_advances[choice];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end
          `I_LD0I: begin
            choice = 2'b0;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            // Although this wont be the actual next dc0, this is necessary to inform everything of what the present
            // dc0's next address is so that things generally work. An exception is made in c0 for this case.
            dc_nexts[0] = dc_read_advances[0];
            dc_nexts[3:1] = dcs[3:1];
            reload = 1'b1;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            // The read address here is what the actual dc0 is going to be set to
            read_address = dc_val0[MAIN_ADDR_WIDTH-1:0];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end
          `I_READS: begin
            choice = 2'bx;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            reload = 1'b0;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = top;
            conveyor_memload = 1'b0;
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
            reload = 1'b1;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = dc_read_advances[choice];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
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
            reload = 1'b1;
            write_out = 1'b1;
            write_address = dc_directions[choice] ? dc_write_advances[choice] : dcs[choice];
            write_value = top;
            read_address = dc_write_advances[choice];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
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
            reload = 1'b1;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = top;
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
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
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end
          `I_READA: begin
            choice = 2'bx;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            reload = 1'b0;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = top;
            conveyor_memload = 1'b1;
            dstack_memload = 1'b0;
          end
          `I_RWRITEZ: begin
            choice = 2'bx;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            reload = 1'b0;
            write_out = 1'b1;
            write_address = alu_out;
            write_value = second;
            read_address = {MAIN_ADDR_WIDTH{1'bx}};
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end
          `I_WRITE: begin
            choice = 2'bx;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            reload = 1'b0;
            write_out = 1'b1;
            write_address = top;
            write_value = second;
            read_address = {MAIN_ADDR_WIDTH{1'bx}};
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end
          `I_ISET: begin
            choice = 2'b0;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts[0] = dc_read_advances[0];
            dc_nexts[3:1] = dcs[3:1];
            reload = 1'b1;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = dc_read_advances[0];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end
          `I_LOOPI: begin
            choice = 2'b0;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts[0] = dc_read_advances[0];
            dc_nexts[3:1] = dcs[3:1];
            reload = 1'b1;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = dc_read_advances[0];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end
          default: begin
            if (jump_immediate) begin
              choice = 2'b0;
              dc_next_directions = dc_directions;
              dc_next_modifies = dc_modifies;
              dc_nexts[0] = dc_read_advances[0];
              dc_nexts[3:1] = dcs[3:1];
              reload = 1'b1;
              write_out = 1'b0;
              write_address = {MAIN_ADDR_WIDTH{1'bx}};
              write_value = {WORD_WIDTH{1'bx}};
              read_address = dc_read_advances[0];
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
            end else if (stream_in) begin
              choice = 2'b0;
              dc_next_directions = dc_directions;
              dc_next_modifies = dc_modifies;
              dc_nexts = dcs;
              reload = 1'b0;
              write_out = 1'b1;
              write_address = stream_address;
              write_value = stream_in_value;
              read_address = {MAIN_ADDR_WIDTH{1'bx}};
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
            end else if (stream_out) begin
              choice = 2'b0;
              dc_next_directions = dc_directions;
              dc_next_modifies = dc_modifies;
              dc_nexts = dcs;
              reload = 1'b0;
              write_out = 1'b0;
              write_address = {MAIN_ADDR_WIDTH{1'bx}};
              write_value = {WORD_WIDTH{1'bx}};
              read_address = stream_address;
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
            end else begin
              choice = 2'bx;
              dc_next_directions = dc_directions;
              dc_next_modifies = dc_modifies;
              dc_nexts = dcs;
              reload = 1'b0;
              write_out = 1'b0;
              write_address = {MAIN_ADDR_WIDTH{1'bx}};
              write_value = {WORD_WIDTH{1'bx}};
              read_address = {MAIN_ADDR_WIDTH{1'bx}};
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
            end
          end
        endcase
      end
    end
  end
endmodule
