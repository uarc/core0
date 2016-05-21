`include "../src/dstack.sv"

module dstack_test;
	logic clk;
  logic reset;
  logic [1:0] movement;
  logic [31:0] next_top;
  wire [31:0] top;
  wire [31:0] second;
  wire [31:0] third;
  logic [5:0] rot_addr;
  wire [31:0] rot_val;
  logic rotate;
  wire overflow;

	localparam S_NOTHING = 2'b00, S_PUSH_ONCE = 2'b01, S_POP_ONCE = 2'b10, S_POP_TWICE = 2'b11;

	dstack #(.WIDTH(32), .DEPTH_MAG(7), .DEPTH(65)) dstack(
		.clk,
		.reset,
		.movement,
		.next_top,
		.top,
		.second,
		.third,
		.rot_addr,
		.rot_val,
		.rotate,
		.overflow
	);

	reg pass;

	initial begin
		$display("dstack test - test results are dependent on previous results");

		reset = 1;
		clk = 0; #1 clk = 1; #1;
		reset = 0;

		movement = S_PUSH_ONCE;
	  next_top = 2;
	  rot_addr = 6'bx;
	  rotate = 0;
		clk = 0; #1 clk = 1; #1
		$display("Push test: %s", top == 2 ? "pass" : "fail");

		next_top = 8;
		clk = 0; #1 clk = 1; #1
		$display("Depth2 test: %s", top == 8 && second == 2 ? "pass" : "fail");

		movement = S_POP_ONCE;
		next_top = second;
		clk = 0; #1 clk = 1; #1
		$display("Pop test: %s", top == 2 ? "pass" : "fail");

		//Push 11
		movement = S_PUSH_ONCE;
		next_top = 11;
		clk = 0; #1 clk = 1; #1
		//Push 12
		next_top = 12;
		clk = 0; #1 clk = 1; #1
		//Double pop
		movement = S_POP_TWICE;
		next_top = third;
		clk = 0; #1 clk = 1; #1
		$display("Double pop test: %s", top == 2 ? "pass" : "fail");

		//Push 33
		movement = S_PUSH_ONCE;
		next_top = 33;
		clk = 0; #1 clk = 1; #1
		//Push 57
		movement = S_PUSH_ONCE;
		next_top = 57;
		clk = 0; #1 clk = 1; #1
		//Push 77
		movement = S_PUSH_ONCE;
		next_top = 77;
		clk = 0; #1 clk = 1; #1
		//Push 79
		movement = S_PUSH_ONCE;
		next_top = 79;
		clk = 0; #1 clk = 1; #1

		//Rotate third element
		rotate = 1;
		movement = S_NOTHING;
		rot_addr = 1;
		next_top = rot_val;
		clk = 0; #1 clk = 1; #1

		//Add first part of test to sequential
		pass = top == 57 && second == 79;

		//Double pop
		rotate = 0;
		rot_addr = 6'bx;
		movement = S_POP_TWICE;
		next_top = third;
		clk = 0; #1 clk = 1; #1

		//Add second part of test to sequential
		pass = pass && top == 77 && second == 33;
		$display("Rotate test: %s", pass ? "pass" : "fail");

		//Copy third element
		movement = S_PUSH_ONCE;
		rot_addr = 1;
		next_top = rot_val;
		clk = 0; #1 clk = 1; #1

		$display("Copy test: %s", top == 2 && second == 77 ? "pass" : "fail");

		//Push 102
		movement = S_PUSH_ONCE;
		rot_addr = 6'bx;
		next_top = 102;
		clk = 0; #1 clk = 1; #1
		//Push 200
		next_top = 200;
		clk = 0; #1 clk = 1; #1
		//Pop and mutate with first + second
		movement = S_POP_ONCE;
		next_top = top + second;
		clk = 0; #1 clk = 1; #1

		$display("Mutate-pop test: %s", top == 302 && second == 2 ? "pass" : "fail");

		//Push 44
		movement = S_PUSH_ONCE;
		next_top = 44;
		clk = 0; #1 clk = 1; #1
		//Push 22
		next_top = 22;
		clk = 0; #1 clk = 1; #1
		//Double pop and mutate with first + second
		movement = S_POP_TWICE;
		next_top = top + second;
		clk = 0; #1 clk = 1; #1

		$display("Mutate-doublepop test: %s", top == 66 && second == 2 ? "pass" : "fail");

		$display("No overflow test: %s", !overflow ? "pass" : "fail");

		//Reset stack
		reset = 1;
		clk = 0; #1 clk = 1; #1;
		reset = 0;

		//Push lots of stuff (65 times)
		movement = S_PUSH_ONCE;
		next_top = 0;
		rot_addr = 6'bx;
		rotate = 0;
		for (int i = 0; i < 64; i++) begin
			clk = 0; #1 clk = 1; #1;
		end
		$display("Overflow test: %s", overflow ? "pass" : "fail");
	end
endmodule
