`include "../src/stack_element.sv"

module stack(
  clk,
  push,
  pop,
  insert,
  tops,
);
  parameter WIDTH = 32;
  /// Depth cannot be less than 2
  parameter DEPTH = 2;
  parameter VISIBLES = 1;

  input clk;
  input push;
  input pop;
  input [WIDTH-1:0] insert;
  output [VISIBLES-1:0][WIDTH-1:0] tops;

  wire [DEPTH-1:0][WIDTH-1:0] data;

  genvar i;

  generate
    for (i = 0; i < VISIBLES; i = i + 1) begin : STACK_TOPS_LOOP
      assign tops[i] = data[i];
    end
  endgenerate

  generate
    for (i = 1; i < DEPTH-1; i = i + 1) begin : STACK_ELEMENT_LOOP
      stack_element #(.WIDTH(WIDTH)) stack_element(
        .clk,
        .push,
        .pop,
        .above(data[i-1]),
        .below(data[i+1]),
        .out(data[i])
      );
    end
  endgenerate

  stack_element #(.WIDTH(WIDTH)) top_element(
    .clk,
    .push,
    .pop,
    .above(insert),
    .below(data[1]),
    .out(data[0])
  );

  stack_element #(.WIDTH(WIDTH)) bottom_element(
    .clk,
    .push,
    .pop,
    .above(data[DEPTH-2]),
    .below({WIDTH{1'bx}}),
    .out(data[DEPTH-1])
  );
endmodule
