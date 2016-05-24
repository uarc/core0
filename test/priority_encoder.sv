`include "../src/priority_encoder.sv"

module priority_encoder_test;
	reg [2:0] lines;
	wire [1:0] out;
	wire on;
	priority_encoder #(.OUT_WIDTH(2), .LINES(3)) enc(
		.lines(lines),
		.out(out),
		.on(on)
	);

	integer i;

	initial begin
		for (i = 0; i < 8; i = i + 1) begin
			lines = i;
			#1 $display("Input = %b, Output = %d, On = %b", lines, out, on);
		end
	end
endmodule
