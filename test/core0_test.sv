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
  localparam CSTACK_DEPTH = 16;
  /// This is how many loops can be nested with the lstack
  localparam LSTACK_DEPTH = 3;
  /// Increasing this by 1 doubles the length of the conveyor buffer
  localparam CONVEYOR_ADDR_WIDTH = 4;

  reg [7:0] programmem [0:PROGRAM_SIZE-1];
  reg [WORD_WIDTH-1:0] mainmem [0:MEMORY_SIZE-1];

  reg clk, reset;
  wire [PROGRAM_ADDR_WIDTH-1:0] programmem_addr;
  reg [7:0] programmem_read_value;
  wire [((PROGRAM_ADDR_WIDTH+WORD_WIDTH/8-1)/(WORD_WIDTH/8))-1:0] programmem_write_addr;
  wire [WORD_WIDTH-1:0] programmem_write_value;
  wire programmem_we;

  wire [MAIN_ADDR_WIDTH-1:0] mainmem_read_addr;
  wire [MAIN_ADDR_WIDTH-1:0] mainmem_write_addr;
  reg [WORD_WIDTH-1:0] mainmem_read_value;
  wire [WORD_WIDTH-1:0] mainmem_write_value;
  wire mainmem_we;

  reg sequential_test_success;

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
      programmem_write_addr,
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

    $readmemh("bin/write.list", programmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 3; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("write: %s", mainmem[0] == 0 ? "pass" : "fail");

    $readmemh("bin/add.list", programmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 5; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("add: %s", core0_base.core0.dstack_top == 0 ? "pass" : "fail");

    $readmemh("bin/synchronous_read.list", programmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 7; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("synchronous read: %s", core0_base.core0.dstack_top == 1 ? "pass" : "fail");

    $readmemh("bin/asynchronous_read.list", programmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 7; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("asynchronous read: %s", core0_base.core0.dstack_top == 1 ? "pass" : "fail");

    $readmemh("bin/multi_async_read.list", programmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("multi async read: %s",
      (core0_base.core0.dstack_top == 2 && core0_base.core0.dstack_second == 1) ? "pass" : "fail");

    $readmemh("bin/rotate.list", programmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 6; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("rotate: %s",
      (core0_base.core0.dstack_top == 2 &&
        core0_base.core0.dstack_second == 0 &&
        core0_base.core0.dstack_third == 0) ? "pass" : "fail");

    $readmemh("bin/copy.list", programmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 5; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("copy: %s",
      (core0_base.core0.dstack_top == 2 &&
        core0_base.core0.dstack_second == 0 &&
        core0_base.core0.dstack_third == 2) ? "pass" : "fail");

    $readmemh("bin/jump.list", programmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 13; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("jump: %s", core0_base.core0.dstack_top == 8 ? "pass" : "fail");

    $readmemh("bin/jump_immediate_prog.list", programmem);
    $readmemh("bin/jump_immediate_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 8; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("jump immediate: %s", core0_base.core0.dstack_top == 1 ? "pass" : "fail");

    $readmemh("bin/add_immediate_prog.list", programmem);
    $readmemh("bin/add_immediate_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 2; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("add immediate: %s", core0_base.core0.dstack_top == 8 ? "pass" : "fail");

    $readmemh("bin/loop_immediate_prog.list", programmem);
    $readmemh("bin/loop_immediate_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 5; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("loop immediate: %s",
      (core0_base.core0.dstack_top == 0 &&
        core0_base.core0.dstack_second == 1 &&
        core0_base.core0.dstack_third == 0) ? "pass" : "fail");

    $readmemh("bin/loop_double_nested_prog.list", programmem);
    $readmemh("bin/loop_double_nested_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 31; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("loop double-nested: %s", core0_base.core0.dstack_top == 2 ? "pass" : "fail");

    $readmemh("bin/calli_prog.list", programmem);
    $readmemh("bin/calli_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 5; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("calli: %s", core0_base.core0.dstack_top == 2 ? "pass" : "fail");

    $readmemh("bin/calli_double_nested_prog.list", programmem);
    $readmemh("bin/calli_double_nested_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 8; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("calli double nested: %s", core0_base.core0.dstack_top == 3 ? "pass" : "fail");

    $readmemh("bin/conditional_branching_prog.list", programmem);
    $readmemh("bin/conditional_branching_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    sequential_test_success = 1'b1;
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 3; i++) begin
      clk = 0; #1; clk = 1; #1;
    end
    sequential_test_success = sequential_test_success && core0_base.core0.pc == 3;
    for (int i = 0; i < 2; i++) begin
      clk = 0; #1; clk = 1; #1;
    end
    sequential_test_success = sequential_test_success && core0_base.core0.pc == 8;

    $display("conditional branching: %s", sequential_test_success ? "pass" : "fail");

    $readmemh("bin/subroutine_dc0_prog.list", programmem);
    $readmemh("bin/subroutine_dc0_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 6; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("subroutine dc0: %s", core0_base.core0.dstack_top == 6 ? "pass" : "fail");

    $readmemh("bin/subroutine_immediate_dc0_prog.list", programmem);
    $readmemh("bin/subroutine_immediate_dc0_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 5; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("subroutine immediate dc0: %s", core0_base.core0.dstack_top == 10 ? "pass" : "fail");

    $readmemh("bin/subroutine_dc0_restore_prog.list", programmem);
    $readmemh("bin/subroutine_dc0_restore_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 6; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("subroutine dc0 restore: %s", core0_base.core0.dstack_top == 10 ? "pass" : "fail");

    $readmemh("bin/writep_prog.list", programmem);
    $readmemh("bin/writep_data.list", mainmem);
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 5; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("writep: %s", core0_base.core0.dstack_top == 1 ? "pass" : "fail");
  end

  genvar gi;
  wire [WORD_WIDTH/8-1:0][7:0] progmem_individuals;
  generate
    for (gi = 0; gi < WORD_WIDTH/8; gi = gi + 1) begin : INDIVIDUAL_PMEM_LOOP
      assign progmem_individuals[gi] = programmem_write_value[gi*8+7:gi*8];
    end
  endgenerate

  always @(posedge clk) begin
    if (programmem_we) begin
      for (int j = 0; j < WORD_WIDTH/8; j++)
        programmem[programmem_write_addr*(WORD_WIDTH/8) + j] <= progmem_individuals[j];
    end
    programmem_read_value <= programmem[programmem_addr];
    if (mainmem_we)
      mainmem[mainmem_write_addr] <= mainmem_write_value;
    mainmem_read_value <= mainmem[mainmem_read_addr];
  end
endmodule
