`include "../src/instructions.sv"
`include "../src/priority_encoder.sv"

module mem_control(
  reset,
  instruction,
  top,
  second,
  alu_out,
  astack_top,
  stream_in,
  stream_in_value,
  stream_out,
  stream_address,
  conveyor_memload_last,
  dstack_memload_last,
  dcs,
  dc_nexts,
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

  input reset;
  input [7:0] instruction;
  input [WORD_WIDTH-1:0] top;
  input [WORD_WIDTH-1:0] second;
  input [MAIN_ADDR_WIDTH-1:0] alu_out;
  input [MAIN_ADDR_WIDTH-1:0] astack_top;
  input stream_in, stream_out;
  input [WORD_WIDTH-1:0] stream_in_value;
  input [MAIN_ADDR_WIDTH-1:0] stream_address;
  input conveyor_memload_last, dstack_memload_last;
  input [3:0][MAIN_ADDR_WIDTH-1:0] dcs;
  output reg [3:0][MAIN_ADDR_WIDTH-1:0] dc_nexts;
  output reg write_out;
  output reg [MAIN_ADDR_WIDTH-1:0] write_address;
  output reg [WORD_WIDTH-1:0] write_value;
  output reg [MAIN_ADDR_WIDTH-1:0] read_address;
  output reg conveyor_memload, dstack_memload;
  output reg reload;
  output reg [1:0] choice;

  always @* begin
    if (reset) begin
      reload = 1'b0;
      choice = 2'bx;
      dc_nexts = {4{{MAIN_ADDR_WIDTH{1'b0}}}};
      write_out = 1'b0;
      write_address = {MAIN_ADDR_WIDTH{1'bx}};
      write_value = {WORD_WIDTH{1'bx}};
      read_address = {MAIN_ADDR_WIDTH{1'b0}};
      conveyor_memload = 1'b0;
      dstack_memload = 1'b0;
    end else begin
      // We need special cases for when we are handling an interrupt (some instructions work fine)
      casez (instruction)
        `I_MOVEZ: begin
          reload = 1'b1;
          choice = instruction[1:0];
          dc_nexts = dcs;
          dc_nexts[choice] = alu_out[MAIN_ADDR_WIDTH-1:0];
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_RAREADZ: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          conveyor_memload = 1'b0;
          dstack_memload = !dstack_memload_last;
        end
        `I_REREADIZ: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          conveyor_memload = 1'b1;
          dstack_memload = 1'b0;
        end
        `I_READZ: begin
          reload = 1'b1;
          choice = instruction[1:0];
          dc_nexts = dcs;
          dc_nexts[choice] = alu_out[MAIN_ADDR_WIDTH-1:0];
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_RAREADIZ: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          conveyor_memload = 1'b0;
          dstack_memload = !dstack_memload_last;
        end
        `I_WRITEPREZ: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          dc_nexts[choice] = alu_out[MAIN_ADDR_WIDTH-1:0];
          write_out = 1'b1;
          write_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          write_value = top;
          // The new dc_val gets assigned directly by top in dc_val_control.
          read_address = {MAIN_ADDR_WIDTH{1'bx}};
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_WRITEPSTZ: begin
          reload = 1'b1;
          choice = instruction[1:0];
          dc_nexts = dcs;
          dc_nexts[choice] = alu_out[MAIN_ADDR_WIDTH-1:0];
          write_out = 1'b1;
          write_address = dcs[instruction[1:0]];
          write_value = top;
          read_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_SETZ: begin
          reload = 1'b1;
          choice = instruction[1:0];
          dc_nexts = dcs;
          dc_nexts[choice] = top[MAIN_ADDR_WIDTH-1:0];
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = top[MAIN_ADDR_WIDTH-1:0];
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_RAWRITEIZ: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          write_out = 1'b1;
          write_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          write_value = top;
          read_address = {MAIN_ADDR_WIDTH{1'bx}};
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_REWRITEIZ: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          write_out = 1'b1;
          write_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          write_value = top;
          read_address = {MAIN_ADDR_WIDTH{1'bx}};
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_REREADZ: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          conveyor_memload = 1'b1;
          dstack_memload = 1'b0;
        end
        `I_REWRITEZ: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          write_out = 1'b1;
          write_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          write_value = second;
          read_address = {MAIN_ADDR_WIDTH{1'bx}};
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_RAWRITEZ: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          write_out = 1'b1;
          write_address = alu_out[MAIN_ADDR_WIDTH-1:0];
          write_value = second;
          read_address = {MAIN_ADDR_WIDTH{1'bx}};
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_WRITE: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          write_out = 1'b1;
          write_address = top;
          write_value = second;
          read_address = {MAIN_ADDR_WIDTH{1'bx}};
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        `I_READ: begin
          reload = 1'b0;
          choice = 2'bx;
          dc_nexts = dcs;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = top[MAIN_ADDR_WIDTH-1:0];
          conveyor_memload = 1'b1;
          dstack_memload = 1'b0;
        end
        `I_POPZ: begin
          reload = 1'b1;
          choice = instruction[1:0];
          dc_nexts = dcs;
          dc_nexts[choice] = astack_top;
          write_out = 1'b0;
          write_address = {MAIN_ADDR_WIDTH{1'bx}};
          write_value = {WORD_WIDTH{1'bx}};
          read_address = astack_top;
          conveyor_memload = 1'b0;
          dstack_memload = 1'b0;
        end
        default: begin
          if (stream_in) begin
            reload = 1'b0;
            choice = 2'bx;
            dc_nexts = dcs;
            write_out = 1'b1;
            write_address = stream_address;
            write_value = stream_in_value;
            read_address = {MAIN_ADDR_WIDTH{1'bx}};
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end else if (stream_out) begin
            reload = 1'b0;
            choice = 2'b0;
            dc_nexts = dcs;
            write_out = 1'b0;
            write_address = {MAIN_ADDR_WIDTH{1'bx}};
            write_value = {WORD_WIDTH{1'bx}};
            read_address = stream_address;
            conveyor_memload = 1'b0;
            dstack_memload = 1'b0;
          end else begin
            reload = 1'b0;
            choice = 2'bx;
            dc_nexts = dcs;
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
endmodule
