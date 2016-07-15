`include "../src/instructions.sv"
`include "../src/priority_encoder.sv"

module mem_control(
  reset,
  instruction,
  jump_immediate,
  lstack_move_beginning,
  lstack_dc0,
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
  loop_memory_conflict_last,
  dcs,
  dc_loadeds,
  dc_val0,
  dc_directions,
  dc_modifies,
  return_dcs,
  return_dc_directions,
  return_dc_modifies,
  dc_nexts,
  dc_loadeds_next,
  dc_next_directions,
  dc_next_modifies,
  write_out,
  write_address,
  write_value,
  read_address,
  conveyor_memload,
  dstack_memload,
  interrupt_memory_conflict,
  loop_memory_conflict,
  reload,
  choice
);
  parameter MAIN_ADDR_WIDTH = 1;
  parameter WORD_WIDTH = 32;

  input reset;
  input [7:0] instruction;
  input jump_immediate;
  input lstack_move_beginning;
  input [MAIN_ADDR_WIDTH-1:0] lstack_dc0;
  input [WORD_WIDTH-1:0] top;
  input [WORD_WIDTH-1:0] second;
  input [MAIN_ADDR_WIDTH-1:0] alu_out;
  input handle_interrupt;
  input [MAIN_ADDR_WIDTH-1:0] interrupt_dc0;
  input stream_in, stream_out;
  input [WORD_WIDTH-1:0] stream_in_value;
  input [MAIN_ADDR_WIDTH-1:0] stream_address;
  input conveyor_memload_last, dstack_memload_last, loop_memory_conflict_last;
  input [3:0][MAIN_ADDR_WIDTH-1:0] dcs;
  input [3:1] dc_loadeds;
  input [WORD_WIDTH-1:0] dc_val0;
  input [3:0] dc_directions;
  input [3:0] dc_modifies;
  input [3:0][MAIN_ADDR_WIDTH-1:0] return_dcs;
  input [3:0] return_dc_directions;
  input [3:0] return_dc_modifies;
  output reg [3:0][MAIN_ADDR_WIDTH-1:0] dc_nexts;
  output reg [3:1] dc_loadeds_next;
  output reg [3:0] dc_next_directions;
  output reg [3:0] dc_next_modifies;
  output reg write_out;
  output reg [MAIN_ADDR_WIDTH-1:0] write_address;
  output reg [WORD_WIDTH-1:0] write_value;
  output reg [MAIN_ADDR_WIDTH-1:0] read_address;
  output reg conveyor_memload, dstack_memload;
  output loop_memory_conflict, interrupt_memory_conflict;
  output reg reload;
  output reg [1:0] choice;

  // Signals for reloader priority encoder
  wire reload_unloaded;
  // This contains a number 1-3, 0 is never included (since dc0 is always loaded)
  wire [1:0] reload_choice;
  // This is the memory address for the dc that must be reloaded
  wire [MAIN_ADDR_WIDTH-1:0] reload_address;

  priority_encoder #(.OUT_WIDTH(2), .LINES(4)) reload_priority_chooser(
    // Insert a 0 where dc0 is so we only get 1-3
    .lines({~dc_loadeds, 1'b0}),
    .out(reload_choice),
    .on(reload_unloaded)
  );

  assign reload_address = dcs[reload_choice];

  wire [3:0][MAIN_ADDR_WIDTH-1:0] dc_read_advances;
  wire [3:0][MAIN_ADDR_WIDTH-1:0] dc_write_advances;

  // Signals for when the DC choice is reloaded
  wire [3:1] loaded_use_reload;
  // Signals for when the reloader choice is used
  wire [3:1] loaded_chooser_reload;

  // This is true when the instruction being executed requires 2 cycles to complete a loop movement.
  reg two_stage_loop_move;
  // This is true if the loop is moving to the beginning but a second stage of the instruction is needed
  // so that the loop's dc0 can be loaded on the following cycle.
  wire loop_first_stage;
  // This is true only if the loop is a two stage loop and its on the final stage.
  wire loop_final_stage;
  // This is true when this cycle the loop beginning is reloaded
  wire loop_beginning_final_stage;

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin : DC_CONTROL_ADVANCE_LOOP
      assign dc_read_advances[i] = dcs[i] + 1;
      assign dc_write_advances[i] = dc_directions[i] ? dcs[i] - 1 : dcs[i] + 1;
    end
  endgenerate

  assign loaded_use_reload = dc_loadeds | ((1 << choice) >> 1);
  assign loaded_chooser_reload = reload_unloaded ? (dc_loadeds | ((1 << reload_choice) >> 1)) : dc_loadeds;

  // loop_memory_conflict only happens on two stage loop moves and when there is no interrupt being handled
  assign loop_memory_conflict = two_stage_loop_move && loop_first_stage && !handle_interrupt;

  assign interrupt_memory_conflict = !reset && handle_interrupt && (
      (instruction == `I_RREADZ && !dstack_memload_last) ||
      (instruction == `I_READS && !dstack_memload_last) ||
      (instruction == `I_READA && !conveyor_memload_last) ||
      // Only stall if the instruction is a two stage loop move and its on the first stage
      (two_stage_loop_move && loop_first_stage)
    );

  assign loop_first_stage = two_stage_loop_move && lstack_move_beginning && !loop_memory_conflict_last;
  assign loop_final_stage = two_stage_loop_move && lstack_move_beginning && loop_memory_conflict_last;
  assign loop_beginning_final_stage = two_stage_loop_move ? loop_final_stage : lstack_move_beginning;

  always @* begin
    if (reset) begin
      choice = 2'b0;
      dc_next_directions = 4'b0;
      dc_next_modifies = 4'b0;
      dc_nexts = {4{{MAIN_ADDR_WIDTH{1'b0}}}};
      dc_loadeds_next = 3'b000;
      reload = 1'b1;
      write_out = 1'b0;
      write_address = {MAIN_ADDR_WIDTH{1'bx}};
      write_value = {WORD_WIDTH{1'bx}};
      read_address = {MAIN_ADDR_WIDTH{1'b0}};
      conveyor_memload = 1'b0;
      dstack_memload = 1'b0;
      two_stage_loop_move = 1'b0;
    end else begin
      // We need special cases for when we are handling an interrupt (some instructions work fine)
      casez (instruction)
        `I_RREADZ: begin
          two_stage_loop_move = 1'b1;
          choice = 2'bx;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          dc_loadeds_next = dc_loadeds;
          reload = 1'b0;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = alu_out;
          conveyor_memload = 1'b0;
          dstack_memload = !dstack_memload_last;
        end
        `I_ADDZ: begin
          // ADD0 is treated differently because at the end of a loop it never stalls
          if (instruction == `I_ADD0) begin
            two_stage_loop_move = 1'b0;
            choice = 2'b0;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            dc_nexts[0] = dc_read_advances[0];
            dc_loadeds_next = dc_loadeds;
            reload = 1'b1;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = dc_read_advances[0];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          // ADD1-3 may stall at the end of a loop because dc0 and the other DC need to load
          end else begin
              two_stage_loop_move = 1'b1;
              choice = instruction[1:0];
              dc_next_directions = dc_directions;
              dc_next_modifies = dc_modifies;
              dc_nexts = dcs;
              dc_nexts[choice] = dc_read_advances[choice];
              dc_loadeds_next = dc_loadeds;
              reload = 1'b1;
              write_out = 1'b0;
              write_address = {MAIN_ADDR_WIDTH{1'bx}};
              write_value = {WORD_WIDTH{1'bx}};
              read_address = dc_read_advances[choice];
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
          end
        end
        `I_RET: begin
          // Having a return at the end of a loop is a dont care case really, so just make it 1 cycle
          two_stage_loop_move = 1'b0;
          choice = 2'b0;
          for (int i = 0; i < 4; i++) begin
            if (dc_modifies[i]) begin
              {dc_nexts[i], dc_next_directions[i], dc_next_modifies[i]} =
                {return_dcs[i], return_dc_directions[i], return_dc_modifies[i]};
            end else begin
              {dc_nexts[i], dc_next_directions[i], dc_next_modifies[i]} = {dcs[i], dc_directions[i], dc_modifies[i]};
            end
          end
          // Any previously unloaded dc or any newly loaded dc in 1-3 is now unloaded
          dc_loadeds_next = ~((~dc_loadeds) | dc_modifies[3:1]);
          reload = 1'b1;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = return_dcs[0];
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_LD0I: begin
          two_stage_loop_move = 1'b0;
          choice = 2'b0;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          // Although this wont be the actual next dc0, this is necessary to inform everything of what the present
          // dc0's next address is so that things generally work. An exception is made in c0 for this case.
          dc_nexts[0] = dc_read_advances[0];
          dc_nexts[3:1] = dcs[3:1];
          dc_loadeds_next = dc_loadeds;
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
          two_stage_loop_move = 1'b1;
          choice = 2'bx;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          dc_loadeds_next = dc_loadeds;
          reload = 1'b0;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = top;
          conveyor_memload = 1'b0;
          dstack_memload = !dstack_memload_last;
        end
        `I_READZ: begin
          // In this case there is no conflict with the loop, so handle it specially
          if (instruction == `I_READ0) begin
            two_stage_loop_move = 1'b0;
            choice = 2'b0;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            dc_nexts[0] = dc_read_advances[0];
            dc_loadeds_next = dc_loadeds;
            reload = 1'b1;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = dc_read_advances[0];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end else begin
            two_stage_loop_move = 1'b1;
            choice = instruction[1:0];
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            dc_nexts[choice] = dc_read_advances[choice];
            dc_loadeds_next = dc_loadeds;
            reload = 1'b1;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = dc_read_advances[choice];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end
        end
        `I_READI: begin
          two_stage_loop_move = 1'b1;
          choice = 2'b0;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          dc_nexts[0] = dc_read_advances[0];
          dc_loadeds_next = dc_loadeds;
          reload = dstack_memload_last;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = dstack_memload_last ? dc_read_advances[0] : dc_val0;
          conveyor_memload = 1'b0;
          dstack_memload = !dstack_memload_last;
        end
        `I_WRITEZ: begin
          // The write has absolutely no conflicts with a loop when its dc0
          if (instruction == `I_WRITE0) begin
              two_stage_loop_move = 1'b0;
              choice = 2'b0;
              dc_next_directions = dc_directions;
              dc_next_modifies = dc_modifies;
              dc_nexts = dcs;
              dc_nexts[0] = dc_write_advances[0];
              dc_loadeds_next = dc_loadeds;
              reload = 1'b1;
              // Write nothing if this is the second cycle of a loop movement (or it will be the wrong address)
              write_out = !loop_final_stage;
              // Handle post-increment (0) vs pre-decrement (1)
              write_address = dc_directions[0] ? dc_write_advances[0] : dcs[0];
              write_value = top;
              read_address = dc_write_advances[0];
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
          end else begin
              two_stage_loop_move = 1'b1;
              choice = instruction[1:0];
              dc_next_directions = dc_directions;
              dc_next_modifies = dc_modifies;
              dc_nexts = dcs;
              dc_nexts[choice] = dc_write_advances[choice];
              // No stall is needed and it is possible we just reloaded a DC, so mark it as loaded
              dc_loadeds_next = loaded_use_reload;
              reload = 1'b1;
              // Write nothing if this is the second cycle of a loop movement (or it will be the wrong address)
              write_out = !loop_final_stage;
              // Handle post-increment (0) vs pre-decrement (1)
              write_address = dc_directions[choice] ? dc_write_advances[choice] : dcs[choice];
              write_value = top;
              read_address = dc_write_advances[choice];
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
          end
        end
        `I_SETFZ: begin
          // No conflict with loops for dc0
          if (instruction == `I_SETF0) begin
              two_stage_loop_move = 1'b0;
              choice = 2'b0;
              dc_next_directions = dc_directions & ~(1 << choice);
              dc_next_modifies = dc_modifies | (1 << choice);
              dc_nexts = dcs;
              dc_nexts[0] = top;
              dc_loadeds_next = dc_loadeds;
              reload = 1'b1;
              write_out = 1'b0;
              write_address = {MAIN_ADDR_WIDTH{1'bx}};
              write_value = {WORD_WIDTH{1'bx}};
              read_address = top;
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
          end else begin
              two_stage_loop_move = 1'b1;
              choice = instruction[1:0];
              dc_next_directions = dc_directions & ~(1 << choice);
              dc_next_modifies = dc_modifies | (1 << choice);
              dc_nexts = dcs;
              dc_nexts[choice] = top;
              // No stall is needed and it is possible we just reloaded a DC, so mark it as loaded
              dc_loadeds_next = loaded_use_reload;
              reload = 1'b1;
              write_out = 1'b0;
              write_address = {MAIN_ADDR_WIDTH{1'bx}};
              write_value = {WORD_WIDTH{1'bx}};
              read_address = top;
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
          end
        end
        `I_SETBZ: begin
          // No conflict with loops for dc0
          if (instruction == `I_SETB0) begin
              two_stage_loop_move = 1'b0;
              choice = 2'b0;
              dc_next_directions = dc_directions | (1 << choice);
              dc_next_modifies = dc_modifies | (1 << choice);
              dc_nexts = dcs;
              dc_nexts[0] = top;
              dc_loadeds_next = dc_loadeds;
              reload = 1'b1;
              write_out = 1'b0;
              write_address = {MAIN_ADDR_WIDTH{1'bx}};
              write_value = {WORD_WIDTH{1'bx}};
              read_address = top;
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
          end else begin
              two_stage_loop_move = 1'b1;
              choice = instruction[1:0];
              dc_next_directions = dc_directions | (1 << choice);
              dc_next_modifies = dc_modifies | (1 << choice);
              dc_nexts = dcs;
              dc_nexts[choice] = top;
              // No stall is needed and it is possible we just reloaded a DC, so mark it as loaded
              dc_loadeds_next = loaded_use_reload;
              reload = 1'b1;
              write_out = 1'b0;
              write_address = {MAIN_ADDR_WIDTH{1'bx}};
              write_value = {WORD_WIDTH{1'bx}};
              read_address = top;
              conveyor_memload = 1'b0;
              dstack_memload = 1'b0;
          end
        end
        `I_READA: begin
          two_stage_loop_move = 1'b1;
          choice = 2'bx;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          // No stall is needed and it is possible we just reloaded a DC, so mark it as loaded
          dc_loadeds_next = loaded_use_reload;
          reload = 1'b0;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = top;
          // Cannot depend on memload last since it might carry from previous instruction
          conveyor_memload = !loop_final_stage;
          dstack_memload = 1'b0;
        end
        `I_WRITEI: begin
          two_stage_loop_move = 1'b0;
          choice = 2'b0;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          dc_nexts[0] = dc_read_advances[0];
          dc_loadeds_next = loaded_chooser_reload;
          // Only reload if the reloader finds an unloaded
          reload = 1'b1;
          write_out = 1'b1;
          write_address = dc_val0;
          write_value = top;
          read_address = dc_read_advances[0];
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_RAWRITEZ: begin
          two_stage_loop_move = 1'b0;
          choice = reload_choice;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          dc_loadeds_next = loaded_chooser_reload;
          // Only reload if the reloader finds an unloaded
          reload = reload_unloaded;
          write_out = 1'b1;
          write_address = alu_out;
          write_value = second;
          read_address = reload_address;
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_REWRITEZ: begin
          // No conflict with loops for dc0
          if (instruction == `I_REWRITE0) begin
            two_stage_loop_move = 1'b0;
            choice = 2'b0;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            dc_nexts[0] = dc_read_advances[0];
            dc_loadeds_next = dc_loadeds;
            // Only reload if the reloader finds an unloaded
            reload = 1'b1;
            write_out = 1'b1;
            write_address = alu_out;
            write_value = second;
            read_address = dc_read_advances[0];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end else begin
            two_stage_loop_move = 1'b1;
            choice = instruction[1:0];
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            dc_nexts[choice] = dc_read_advances[0];
            // No stall is needed and it is possible we just reloaded a DC, so mark it as loaded
            dc_loadeds_next = loaded_use_reload;
            reload = 1'b1;
            write_out = 1'b1;
            write_address = alu_out;
            write_value = second;
            read_address = dc_read_advances[0];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end
        end
        `I_WRITE: begin
          two_stage_loop_move = 1'b0;
          choice = reload_choice;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          dc_loadeds_next = loaded_chooser_reload;
          reload = reload_unloaded;
          write_out = 1'b1;
          write_address = top;
          write_value = second;
          read_address = reload_address;
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_ISET: begin
          // This only uses dc0 so there is no conflict
          two_stage_loop_move = 1'b0;
          choice = 2'b0;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          dc_nexts[0] = dc_read_advances[0];
          dc_loadeds_next = dc_loadeds;
          reload = 1'b1;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = dc_read_advances[0];
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_LOOPI: begin
          // This only uses dc0 so there is no conflict
          two_stage_loop_move = 1'b0;
          choice = 2'b0;
          dc_next_directions = dc_directions;
          dc_next_modifies = dc_modifies;
          dc_nexts = dcs;
          dc_nexts[0] = dc_read_advances[0];
          dc_loadeds_next = dc_loadeds;
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
            // This really doesn't make any sense, so just let the processor execute this in one cycle
            two_stage_loop_move = 1'b0;
            choice = 2'b0;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            dc_nexts[0] = dc_read_advances[0];
            dc_loadeds_next = dc_loadeds;
            reload = 1'b1;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = dc_read_advances[0];
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end else if (stream_in) begin
            // TODO: Ensure that dc0 gets reloaded properly after a stream_in at a loop movement (test)
            // If this is the last instruction in the loop, this is going to be confusing
            two_stage_loop_move = 1'b0;
            choice = 2'b0;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            // The stream would conflict with any loading
            dc_loadeds_next = dc_loadeds;
            reload = 1'b0;
            write_out = 1'b1;
            write_address = stream_address;
            write_value = stream_in_value;
            read_address = {MAIN_ADDR_WIDTH{1'bx}};
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end else if (stream_out) begin
            // TODO: Ensure that dc0 gets reloaded properly after a stream_out at a loop movement (test)
            // If this is the last instruction in the loop, this is going to be confusing
            two_stage_loop_move = 1'b0;
            choice = 2'b0;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            // The stream would conflict with any loading
            dc_loadeds_next = dc_loadeds;
            reload = 1'b0;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = stream_address;
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end else begin
            two_stage_loop_move = 1'b0;
            choice = reload_choice;
            dc_next_directions = dc_directions;
            dc_next_modifies = dc_modifies;
            dc_nexts = dcs;
            dc_loadeds_next = loaded_chooser_reload;
            reload = reload_unloaded;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = reload_address;
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end
        end
      endcase
      // After everything else, the loop beginning applies where necessary
      if (loop_beginning_final_stage) begin
        choice = 2'b0;
        reload = 1'b1;
        dc_nexts = dcs;
        dc_nexts[0] = lstack_dc0;
        // We are loading dc0, so we need to ignore other reloads
        dc_loadeds_next = dc_loadeds;
        read_address = lstack_dc0;
      end
      // Change values if the interrupt case is true
      // The interrupt always overrides everything else
      if (handle_interrupt) begin
        choice = 2'b0;
        reload = 1'b1;
        // We are loading dc0, so we need to ignore other reloads
        dc_loadeds_next = dc_loadeds;
        read_address = interrupt_dc0;
        // All multi-cycle operations will not occur and it stalls appropriately on each case
        conveyor_memload = 1'b0;
        dstack_memload = 1'b0;
      end
    end
  end
endmodule
