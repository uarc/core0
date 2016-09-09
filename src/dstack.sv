/// The module for the core0 dstack
module dstack(
  clk,
  reset,
  movement,
  next_top,
  top,
  second,
  third,
  rot_addr,
  rot_val,
  rotate,
  overflow,
  underflow
);
  /// The log2 of the depth of the stack
  parameter DEPTH_MAG = 7;
  /// This must always be less than or equal to 1 << DEPTH_MAG and will adjust itself
  parameter DEPTH = 1 << DEPTH_MAG;
  /// The width of words in the stack
  parameter WIDTH = 32;

  input clk;
  /// `reset` only resets the depth for overflow purposes
  input reset;
  /// 00 is do nothing
  /// 01 is push once
  /// 10 is pop once
  /// 11 is pop twice
  input [1:0] movement;
  /// What to replace the old top with
  input [WIDTH-1:0] next_top;
  /// The top of the stack
  output reg [WIDTH-1:0] top;
  /// The value under the top
  output [WIDTH-1:0] second;
  /// The value under the second
  output [WIDTH-1:0] third;
  /// The last address which is pushed during a rotate
  input [4:0] rot_addr;
  /// The value rotated to the top in a rotate
  output [WIDTH-1:0] rot_val;
  /// The signal to rotate the stack is passed explicitly along with 00 for movement
  input rotate;
  /// A signal indicating if a value was lost at the bottom of the stack from pushing too much
  output overflow, underflow;

  reg [DEPTH_MAG-1:0] depth;
  wire [DEPTH-1:0][WIDTH-1:0] elements;

  assign elements[0] = top;
  assign rot_val = elements[rot_addr];

  assign second = elements[1];
  assign third = elements[2];

  // Overflow only happens when we push a full stack
  // We don't stop the overflow/data deletion, just trigger a fault, so no special code is necessary
  // When an overflow occurs the depth returns to 0, effectively automatically resetting the stack
  assign overflow = movement == 2'b01 && (depth == DEPTH - 1);
  assign underflow = (movement == 2'b10 && (depth == 0)) || (movement == 2'b11 && (depth <= 1));

  genvar i;
  generate
    for (i = 1; i < DEPTH-2; i = i + 1) begin : DSTACK_ELEMENTS
      dstack_element #(.WIDTH(WIDTH)) dstack_element(
        .clk,
        .movement(
          rotate ? (
            // Handle the rotate case
            // All values above and equal to the rotate address must be pushed down
            i <= rot_addr ? 2'b01 : movement
          // The copy case is handled implicitly because all elements are pushed once
          ) : movement
        ),
        .above(elements[i-1]),
        .below(elements[i+1]),
        .below_twice(elements[i+2]),
        .out(elements[i])
      );
    end
  endgenerate

  // The last two stack elements are a corner case
  dstack_element #(.WIDTH(WIDTH)) dstack_element_second_last(
    .clk,
    .movement(
      rotate ? (
        // Handle the rotate case
        // All values above and equal to the rotate address must be pushed down
        DEPTH-2 <= rot_addr ? 2'b01 : movement
      // The copy case is handled implicitly because all elements are pushed once
      ) : movement
    ),
    .above(elements[DEPTH-3]),
    .below(elements[DEPTH-1]),
    .below_twice({WIDTH{1'bx}}),
    .out(elements[DEPTH-2])
  );

  dstack_element #(.WIDTH(WIDTH)) dstack_element_last(
    .clk,
    .movement(
      rotate ? (
        // Handle the rotate case
        // All values above and equal to the rotate address must be pushed down
        DEPTH-1 <= rot_addr ? 2'b01 : movement
      // The copy case is handled implicitly because all elements are pushed once
      ) : movement
    ),
    .above(elements[DEPTH-2]),
    .below({WIDTH{1'bx}}),
    .below_twice({WIDTH{1'bx}}),
    .out(elements[DEPTH-1])
  );

  always @(posedge clk) begin
    // Always replace top with next_top even on rotate
    top <= next_top;
    if (reset) begin
      depth <= 0;
    end else begin
      case (movement)
        // No movement
        2'b00: depth <= depth;
        // Push
        2'b01: depth <= depth + 1;
        // Pop
        2'b10: depth <= depth - 1;
        // Double pop
        2'b11: depth <= depth - 2;
      endcase
    end
  end
endmodule

module dstack_element(
  clk,
  movement,
  above,
  below,
  below_twice,
  out
);
  parameter WIDTH = 32;
  input clk;
  input [1:0] movement;
  input [WIDTH-1:0] above;
  input [WIDTH-1:0] below;
  input [WIDTH-1:0] below_twice;
  output reg [WIDTH-1:0] out;

  always @(posedge clk) begin
    case (movement)
      // No movement
      2'b00: out <= out;
      // Push
      2'b01: out <= above;
      // Pop
      2'b10: out <= below;
      // Double pop
      2'b11: out <= below_twice;
    endcase
  end
endmodule
