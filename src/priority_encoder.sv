`ifndef PRIORITY_ENCODER_SV
`define PRIORITY_ENCODER_SV
module priority_encoder(
	lines,
	out,
	on
);
	/// The width if the index address output
	parameter OUT_WIDTH = 1;
	/// The amount of actual lines which must be less than or equal to 1 << OUT_WIDTH
	parameter LINES = 1 << OUT_WIDTH;

	input [LINES-1:0] lines;
	output [OUT_WIDTH-1:0] out;
	output on;

	wire [LINES:0] intermediate_ands;
	wire [LINES:0] intermediate_ors;
	wire [LINES:0] intermediate_out_ors [OUT_WIDTH-1:0];

	assign intermediate_ands[LINES] = 1;
	assign intermediate_ors[LINES] = 0;
	assign intermediate_ands[LINES-1] = lines[LINES-1];
	assign intermediate_ors[LINES-1] = lines[LINES-1];

	assign on = intermediate_ors[0];

	genvar i;
	genvar j;

	generate
		for (i = 0; i < LINES-1; i = i + 1) begin : ENTRY_LOOP
			assign intermediate_ands[i] = ~intermediate_ors[i+1] & lines[i];
			assign intermediate_ors[i] = intermediate_ors[i+1] | lines[i];
		end
	endgenerate

	generate
		for (i = 0; i < OUT_WIDTH; i = i + 1) begin : OUT_LOOP
			assign intermediate_out_ors[i][LINES] = 0;
			assign out[i] = intermediate_out_ors[i][0];
			for (j = LINES-1; j >= 0; j = j - 1) begin : OUT_OR_LOOP
				assign intermediate_out_ors[i][j] = intermediate_out_ors[i][j+1] |
					(((j & (1 << i)) != 0) && (intermediate_ands[j]));
			end
		end
	endgenerate
endmodule
`endif
