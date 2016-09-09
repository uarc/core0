`include "../test/core0_base.sv"

module core0_test;
  /// The log2 of the word width of the core
  localparam WORD_MAG = 5;
  localparam WORD_WIDTH = 1 << WORD_MAG;
  /// Each set contains WORD_WIDTH amount of buses.
  /// Not all of these buses need to be connected to an actual core.
  localparam UARC_SETS = 1;
  /// Must be less than or equal to UARC_SETS * WORD_WIDTH
  localparam TOTAL_BUSES = 1;
  /// This is the width of the program memory address bus
  localparam PROGRAM_ADDR_WIDTH = 5;
  localparam PROGRAM_SIZE = 1 << PROGRAM_ADDR_WIDTH;
  /// This is the width of the main memory address bus
  localparam MAIN_ADDR_WIDTH = 3;
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
  reg [(8 + WORD_WIDTH)-1:0] programmem_read_value;
  wire [PROGRAM_ADDR_WIDTH-1:0] programmem_write_addr;
  wire [WORD_WIDTH/8-1:0] programmem_byte_write_mask;
  wire [WORD_WIDTH-1:0] programmem_write_value;
  wire programmem_we;

  wire [MAIN_ADDR_WIDTH-1:0] mainmem_read_addr;
  wire [MAIN_ADDR_WIDTH-1:0] mainmem_write_addr;
  reg [WORD_WIDTH-1:0] mainmem_read_value;
  wire [WORD_WIDTH-1:0] mainmem_write_value;
  wire mainmem_we;

  wire global_kill;
  wire global_incept;
  wire global_send;
  wire global_stream;
  wire [WORD_WIDTH-1:0] global_data;
  wire [WORD_WIDTH-1:0] global_self_permission;
  wire [WORD_WIDTH-1:0] global_self_address;
  wire [WORD_WIDTH-1:0] global_incept_permission;
  wire [WORD_WIDTH-1:0] global_incept_address;

  // All of the signals for each bus for when this core is acting as the sender
  wire [TOTAL_BUSES-1:0] sender_enables;
  wire [TOTAL_BUSES-1:0] sender_kill_acks;
  wire [TOTAL_BUSES-1:0] sender_incept_acks;
  wire [TOTAL_BUSES-1:0] sender_send_acks;
  wire [TOTAL_BUSES-1:0] sender_stream_acks;

  // All of the signals for each bus for when this core is acting as the receiver
  wire [TOTAL_BUSES-1:0] receiver_enables;
  wire [TOTAL_BUSES-1:0] receiver_kills;
  wire [TOTAL_BUSES-1:0] receiver_kill_acks;
  wire [TOTAL_BUSES-1:0] receiver_incepts;
  wire [TOTAL_BUSES-1:0] receiver_incept_acks;
  reg [TOTAL_BUSES-1:0] receiver_sends;
  wire [TOTAL_BUSES-1:0] receiver_send_acks;
  wire [TOTAL_BUSES-1:0] receiver_streams;
  wire [TOTAL_BUSES-1:0] receiver_stream_acks;
  reg [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_datas;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_self_permissions;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_self_addresses;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_incept_permissions;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_incept_addresses;

  assign sender_kill_acks = {TOTAL_BUSES{1'b0}};
  assign sender_incept_acks = {TOTAL_BUSES{1'b0}};
  assign sender_send_acks = {TOTAL_BUSES{1'b0}};
  assign sender_stream_acks = {TOTAL_BUSES{1'b0}};

  assign receiver_enables = 1'b1;
  assign receiver_kills = {TOTAL_BUSES{1'b0}};
  assign receiver_incepts = {TOTAL_BUSES{1'b0}};
  assign receiver_streams = {TOTAL_BUSES{1'b0}};
  assign receiver_self_permissions = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
  assign receiver_self_addresses = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
  assign receiver_incept_permissions = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
  assign receiver_incept_addresses = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};

  reg sequential_test_success;

  core0_base #(
      .WORD_MAG(5),
      .UARC_SETS(UARC_SETS),
      .TOTAL_BUSES(TOTAL_BUSES),
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
      programmem_byte_write_mask,
      programmem_write_value,
      programmem_we,

      mainmem_read_addr,
      mainmem_write_addr,
      mainmem_read_value,
      mainmem_write_value,
      mainmem_we,

      global_kill,
      global_incept,
      global_send,
      global_stream,
      global_data,
      global_self_permission,
      global_self_address,
      global_incept_permission,
      global_incept_address,

      sender_enables,
      sender_kill_acks,
      sender_incept_acks,
      sender_send_acks,
      sender_stream_acks,

      receiver_enables,
      receiver_kills,
      receiver_kill_acks,
      receiver_incepts,
      receiver_incept_acks,
      receiver_sends,
      receiver_send_acks,
      receiver_streams,
      receiver_stream_acks,
      receiver_datas,
      receiver_self_permissions,
      receiver_self_addresses,
      receiver_incept_permissions,
      receiver_incept_addresses
    );

  initial begin
    $dumpfile("test.vcd");
    $dumpvars;

    $readmemh("bin/write.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 10; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("write: %s", mainmem[0] == 7 ? "pass" : "fail");

    $readmemh("bin/add.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 10; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("add: %s", core0_base.core0.dstack_top == 0 ? "pass" : "fail");

    $readmemh("bin/asynchronous_read.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 10; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("asynchronous read: %s", core0_base.core0.dstack_top == 7 ? "pass" : "fail");

    $readmemh("bin/multi_async_read.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("multi async read: %s",
      (core0_base.core0.dstack_top == 8 && core0_base.core0.dstack_second == 7) ? "pass" : "fail");

    $readmemh("bin/rotate.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("rotate: %s",
      (core0_base.core0.dstack_top == 2 &&
        core0_base.core0.dstack_second == 0 &&
        core0_base.core0.dstack_third == 0) ? "pass" : "fail");

    $readmemh("bin/copy.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("copy: %s",
      (core0_base.core0.dstack_top == 2 &&
        core0_base.core0.dstack_second == 0 &&
        core0_base.core0.dstack_third == 2) ? "pass" : "fail");

    $readmemh("bin/jump.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 13; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("jump: %s", core0_base.core0.dstack_top == 8 ? "pass" : "fail");

    $readmemh("bin/jump_immediate.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("jump immediate: %s", core0_base.core0.dstack_top == 8 ? "pass" : "fail");

    $readmemh("bin/add_immediate.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("add immediate: %s", core0_base.core0.dstack_top == 8 ? "pass" : "fail");

    $readmemh("bin/loop.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("loop: %s",
      (core0_base.core0.dstack_top == 2 &&
        core0_base.core0.dstack_second == 1 &&
        core0_base.core0.dstack_third == 0) ? "pass" : "fail");

    $readmemh("bin/loop_double_nested.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 32; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("loop double-nested: %s", core0_base.core0.dstack_top == 2 &&
      core0_base.core0.dstack_second == 1 ? "pass" : "fail");

    $readmemh("bin/calli.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("calli: %s", core0_base.core0.dstack_top == 11 && core0_base.core0.dstack_second == 10 ? "pass" : "fail");

    $readmemh("bin/calli_double_nested.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("calli double nested: %s",
      core0_base.core0.dstack_top == 11 && core0_base.core0.dstack_second == 10 ? "pass" : "fail");

    $readmemh("bin/conditional_branching.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    sequential_test_success = 1'b1;
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("conditional branching: %s", core0_base.core0.dstack_top == 6 && core0_base.core0.dstack_second == 5 ? "pass" : "fail");

    $readmemh("bin/writep.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("writep: %s", core0_base.core0.dstack_top == 6 ? "pass" : "fail");

    $readmemh("bin/interrupt.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    // Give it a sufficient amount of cycles to set up and do other things
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end
    // Now interrupt it
    receiver_sends = 1'b1;
    receiver_datas[0] = 88;
    // Check to make sure it acknowledges the interrupt
    #1 sequential_test_success = receiver_send_acks[0];
    // Clock it once to enter the interrupt
    clk = 0; #1; clk = 1; #1;
    // Unassert the interrupt, now that it has been acknowledged
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    // Ensure it only acks on the cycle it accepts the interrupt.
    #1 sequential_test_success = sequential_test_success && !receiver_send_acks[0];
    // Clock it again to run the first instruction
    clk = 0; #1; clk = 1; #1;

    $display("interrupt: %s", sequential_test_success && core0_base.core0.dstack_top == 8 ? "pass" : "fail");

    $readmemh("bin/interrupt_value.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    // Give it a sufficient amount of cycles to set up and do other things
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end
    // Now interrupt it
    receiver_sends = 1'b1;
    receiver_datas[0] = 88;
    // Check to make sure it acknowledges the interrupt
    #1 sequential_test_success = receiver_send_acks[0];
    // Clock it once to enter the interrupt
    clk = 0; #1; clk = 1; #1;
    // Unassert the interrupt, now that it has been acknowledged
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    // Ensure it only acks on the cycle it accepts the interrupt.
    #1 sequential_test_success = sequential_test_success && !receiver_send_acks[0];
    // Clock it again to run the first instruction
    clk = 0; #1; clk = 1; #1;

    $display("interrupt value: %s", sequential_test_success && core0_base.core0.dstack_top == 88 ? "pass" : "fail");

    $readmemh("bin/loop_none.list", programmem);
    receiver_sends = {TOTAL_BUSES{1'b0}};
    receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
    programmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    mainmem_read_value <= {MAIN_ADDR_WIDTH{1'bx}};
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    // Give it a sufficient amount of cycles to set up and do other things
    for (int i = 0; i < 16; i++) begin
      clk = 0; #1; clk = 1; #1;
    end

    $display("loop none: %s", core0_base.core0.dstack_top == 8 ? "pass" : "fail");
  end

  wire [(8 + WORD_WIDTH)-1:0] full_read_value;
  wire [WORD_WIDTH/8-1:0][7:0] individual_write_values;

  genvar i;
  generate
    for (i = 0; i < WORD_WIDTH/8 + 1; i = i + 1) begin : FULL_VALUE_LOOP
      assign full_read_value[i*8+7:i*8] = programmem[programmem_addr + i];
    end
    for (i = 0; i < WORD_WIDTH/8; i = i + 1) begin : INDIVIDUAL_OCTET_LOOP
      assign individual_write_values[i] = programmem_write_value[i*8+7:i*8];
    end
  endgenerate

  always @(posedge clk) begin
    if (programmem_we) begin
      for (int j = 0; j < WORD_WIDTH/8; j++)
        if (programmem_byte_write_mask[j])
          programmem[programmem_write_addr + j] <= individual_write_values[j];
    end
    for (int j = 0; j < WORD_WIDTH/8 + 1; j++)
      programmem_read_value <= full_read_value;
    if (mainmem_we)
      mainmem[mainmem_write_addr] <= mainmem_write_value;
    mainmem_read_value <= mainmem[mainmem_read_addr];
  end
endmodule
