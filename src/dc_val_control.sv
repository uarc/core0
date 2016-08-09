`include "../src/instructions.sv"
module dc_val_control(
  instruction,
  top,
  dc_vals,
  dc_reload,
  dc_mutate,
  mem_in,
  dc_vals_next
);
  parameter WORD_WIDTH = 32;

  input [7:0] instruction;
  input [WORD_WIDTH-1:0] top;
  input [3:0][WORD_WIDTH-1:0] dc_vals;
  input dc_reload;
  input [1:0] dc_mutate;
  input [WORD_WIDTH-1:0] mem_in;
  output reg [3:0][WORD_WIDTH-1:0] dc_vals_next;

  always @* begin
    for (int i = 0; i < 4; i++) begin
      if (instruction[7:2] == `I_WRITEPREM && instruction[1:0] == i[1:0])
        dc_vals_next[i] = top;
      else
        dc_vals_next[i] = (dc_reload && i == dc_mutate) ? mem_in : dc_vals[i];
    end
  end
endmodule
