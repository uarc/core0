`include "../test/core0_base.sv"

module core0_uforth;
  /// The log2 of the word width of the core
  localparam WORD_MAG = 5;
  localparam WORD_WIDTH = 1 << WORD_MAG;
  /// Each set contains WORD_WIDTH amount of buses.
  /// Not all of these buses need to be connected to an actual core.
  localparam UARC_SETS = 1;
  /// Must be less than or equal to UARC_SETS * WORD_WIDTH
  localparam TOTAL_BUSES = 1;
  /// This is the width of the program memory address bus
  localparam PROGRAM_ADDR_WIDTH = 11;
  localparam PROGRAM_SIZE = 1 << PROGRAM_ADDR_WIDTH;
  /// This is the width of the main memory address bus
  localparam MAIN_ADDR_WIDTH = 11;
  localparam MEMORY_SIZE = 1 << MAIN_ADDR_WIDTH;
  /// This is how many recursions are possible with the cstack
  localparam CSTACK_DEPTH = 16;
  /// This is how many loops can be nested with the lstack
  localparam LSTACK_DEPTH = 3;
  /// Increasing this by 1 doubles the length of the conveyor buffer
  localparam CONVEYOR_ADDR_WIDTH = 4;

  localparam STDIN = 32'h8000_0000;
  localparam STDOUT = 32'h8000_0001;

  reg [7:0] programmem [0:PROGRAM_SIZE-1];
  reg [WORD_WIDTH-1:0] mainmem [0:MEMORY_SIZE-1];

  reg clk, reset;
  wire [PROGRAM_ADDR_WIDTH-1:0] programmem_addr;
  reg [7:0] programmem_read_value;
  wire [((PROGRAM_ADDR_WIDTH+WORD_WIDTH/8-1)/(WORD_WIDTH/8))-1:0] programmem_write_addr;
  wire [WORD_WIDTH-1:0] programmem_write_mask;
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
  reg [TOTAL_BUSES-1:0] sender_send_acks;
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
  assign sender_stream_acks = {TOTAL_BUSES{1'b0}};

  assign receiver_enables = 1'b1;
  assign receiver_kills = {TOTAL_BUSES{1'b0}};
  assign receiver_incepts = {TOTAL_BUSES{1'b0}};
  assign receiver_streams = {TOTAL_BUSES{1'b0}};
  assign receiver_self_permissions = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
  assign receiver_self_addresses = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
  assign receiver_incept_permissions = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
  assign receiver_incept_addresses = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};

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
      programmem_write_mask,
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

    $readmemh("bin/uforth_prog.list", programmem);
    $readmemh("bin/uforth_data.list", mainmem);
    reset = 1;
    clk = 0; #1; clk = 1; #1;
    reset = 0;
    while (!$feof(STDIN)) begin
      reg [7:0] in_char;
      reg count;
      integer rval;
      if (receiver_sends) begin
        if (receiver_send_acks) begin
          receiver_sends = 0;
          count = $fread(in_char, STDIN, 1);
          if (count) begin
            $display("%c", in_char);
            receiver_sends = 1;
          end
        end
      end else begin
        count = $fread(in_char, STDIN, 1);
        if (count) begin
          $display("%c", in_char);
          receiver_sends = 1;
        end
      end
      if (sender_enables[0] && global_send) begin
        rval = $fputc(global_data, STDOUT);
        if (rval == -1)
          $finish;
        sender_send_acks = 1;
      end else
        sender_send_acks = 0;
      clk = 0; #1; clk = 1; #1;
    end
  end

  genvar gi;
  wire [WORD_WIDTH/8-1:0][7:0] progmem_individuals;
  wire [WORD_WIDTH/8-1:0][7:0] progmem_individual_masks;
  generate
    for (gi = 0; gi < WORD_WIDTH/8; gi = gi + 1) begin : INDIVIDUAL_PMEM_LOOP
      assign progmem_individuals[gi] = programmem_write_value[gi*8+7:gi*8];
      assign progmem_individual_masks[gi] = programmem_write_mask[gi*8+7:gi*8];
    end
  endgenerate

  always @(posedge clk) begin
    if (programmem_we) begin
      for (int j = 0; j < WORD_WIDTH/8; j++)
        programmem[programmem_write_addr*(WORD_WIDTH/8) + j] <=
          (programmem[programmem_write_addr*(WORD_WIDTH/8) + j] & (~progmem_individual_masks[j])) |
          (progmem_individuals[j] & progmem_individual_masks[j]);
    end
    programmem_read_value <= programmem[programmem_addr];
    if (mainmem_we)
      mainmem[mainmem_write_addr] <= mainmem_write_value;
    mainmem_read_value <= mainmem[mainmem_read_addr];
  end
endmodule
