module stack_element(
	clk,
	push,
	pop,
	above,
	below,
	out
);
	parameter WIDTH = 32;

	input clk;
	input push;
	input pop;
	input [WIDTH-1:0] above;
	input [WIDTH-1:0] below;
	output reg [WIDTH-1:0] out;

	always @(posedge clk) begin
		if (push)
			out <= above;
		if (pop)
			out <= below;
	end
endmodule
