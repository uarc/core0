module dc_val_control(
  dc_vals,
  dc_reload,
  dc_mutate,
  mem_in,
  dc_vals_next
);
  parameter WORD_WIDTH = 32;

  input [3:0][WORD_WIDTH-1:0] dc_vals;
  input dc_reload;
  input [1:0] dc_mutate;
  input [WORD_WIDTH-1:0] mem_in;
  output reg [3:0][WORD_WIDTH-1:0] dc_vals_next;

  always @* begin
    for (int i = 0; i < 4; i++)
      dc_vals_next[i] = (dc_reload && i == dc_mutate) ? mem_in : dc_vals[i];
  end
endmodule
