`include "../test/core0_base.sv"

module core0_test;
  /// The log2 of the word width of the core
  localparam WORD_MAG = 5;
  localparam WORD_WIDTH = 1 << WORD_MAG;
  /// This is the width of the program memory address bus
  localparam PROGRAM_ADDR_WIDTH = 5;
  localparam PROGRAM_SIZE = 1 << PROGRAM_ADDR_WIDTH;
  /// This is the width of the main memory address bus
  localparam MAIN_ADDR_WIDTH = 2;
  localparam MEMORY_SIZE = 1 << MAIN_ADDR_WIDTH;
  /// This is how many recursions are possible with the cstack
  localparam CSTACK_DEPTH = 2;
  /// This is how many loops can be nested with the lstack
  localparam LSTACK_DEPTH = 3;
  /// Increasing this by 1 doubles the length of the conveyor buffer
  localparam CONVEYOR_ADDR_WIDTH = 4;

  reg [7:0] programmem [0:PROGRAM_SIZE-1];
  reg [WORD_WIDTH-1:0] mainmem [0:MEMORY_SIZE-1];

  reg clk, reset;
  wire [PROGRAM_ADDR_WIDTH-1:0] programmem_addr;
  reg [7:0] programmem_read_value;
  wire [WORD_WIDTH-1:0] programmem_write_value;
  wire programmem_we;

  wire [MAIN_ADDR_WIDTH-1:0] mainmem_read_addr;
  wire [MAIN_ADDR_WIDTH-1:0] mainmem_write_addr;
  reg [WORD_WIDTH-1:0] mainmem_read_value;
  wire [WORD_WIDTH-1:0] mainmem_write_value;
  wire mainmem_we;

  core0_base #(
      .WORD_MAG(5),
      .PROGRAM_ADDR_WIDTH(PROGRAM_ADDR_WIDTH),
      .MAIN_ADDR_WIDTH(MAIN_ADDR_WIDTH),
      .CSTACK_DEPTH(CSTACK_DEPTH),
      .LSTACK_DEPTH(LSTACK_DEPTH),
      .CONVEYOR_ADDR_WIDTH(CONVEYOR_ADDR_WIDTH)
    ) core0_base (
      clk,
      reset,

      programmem_addr,
      programmem_read_value,
      programmem_write_value,
      programmem_we,

      mainmem_read_addr,
      mainmem_write_addr,
      mainmem_read_value,
      mainmem_write_value,
      mainmem_we
    );

  initial begin
    $dumpfile("test.vcd");
    $dumpvars;
    $readmemh("bin/test1.list", programmem);

    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    clk = 0; #1; clk = 1; #1;
    clk = 0; #1; clk = 1; #1;
    clk = 0; #1; clk = 1; #1;

    // Test for test1 condition
    $display("test 1: %s", mainmem[0] == {WORD_WIDTH{1'b0}} ? "pass" : "fail");
  end

  always @(posedge clk) begin
    if (reset) begin
      programmem_read_value <= programmem[0];
      mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    end else begin
      if (programmem_we)
        programmem[programmem_addr] <= programmem_write_value;
      programmem_read_value <= programmem[programmem_addr];
      if (mainmem_we)
        mainmem[mainmem_write_addr] <= mainmem_write_value;
      mainmem_read_value <= mainmem[mainmem_read_addr];
    end
  end
endmodule
