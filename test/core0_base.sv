`include "../src/core0.sv"

module core0_base(
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
  /// The log2 of the word width of the core
  parameter WORD_MAG = 5;
  localparam WORD_WIDTH = 1 << WORD_MAG;
  /// Each set contains WORD_WIDTH amount of buses.
  /// Not all of these buses need to be connected to an actual core.
  localparam UARC_SETS = 1;
  /// Must be less than or equal to UARC_SETS * WORD_WIDTH
  localparam TOTAL_BUSES = 1;
  /// This is the width of the program memory address bus
  parameter PROGRAM_ADDR_WIDTH = 1;
  /// This is the width of the main memory address bus
  parameter MAIN_ADDR_WIDTH = 1;
  /// This is how many recursions are possible with the cstack
  parameter CSTACK_DEPTH = 2;
  /// This is how many loops can be nested with the lstack
  parameter LSTACK_DEPTH = 3;
  /// Increasing this by 1 doubles the length of the conveyor buffer
  parameter CONVEYOR_ADDR_WIDTH = 4;

  input clk, reset;
  output [PROGRAM_ADDR_WIDTH-1:0] programmem_addr;
  input [7:0] programmem_read_value;
  output [((PROGRAM_ADDR_WIDTH+WORD_WIDTH/8-1)/(WORD_WIDTH/8))-1:0] programmem_write_addr;
  output [WORD_WIDTH-1:0] programmem_write_value;
  output programmem_we;

  output [MAIN_ADDR_WIDTH-1:0] mainmem_read_addr;
  output [MAIN_ADDR_WIDTH-1:0] mainmem_write_addr;
  input [WORD_WIDTH-1:0] mainmem_read_value;
  output [WORD_WIDTH-1:0] mainmem_write_value;
  output mainmem_we;

  // All of the outgoing signals connected to every bus
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
  wire [TOTAL_BUSES-1:0] receiver_sends;
  wire [TOTAL_BUSES-1:0] receiver_send_acks;
  wire [TOTAL_BUSES-1:0] receiver_streams;
  wire [TOTAL_BUSES-1:0] receiver_stream_acks;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_datas;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_self_permissions;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_self_addresses;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_incept_permissions;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_incept_addresses;

  assign sender_kill_acks = {TOTAL_BUSES{1'b0}};
  assign sender_incept_acks = {TOTAL_BUSES{1'b0}};
  assign sender_send_acks = {TOTAL_BUSES{1'b0}};
  assign sender_stream_acks = {TOTAL_BUSES{1'b0}};

  assign receiver_enables = {TOTAL_BUSES{1'b0}};
  assign receiver_kills = {TOTAL_BUSES{1'b0}};
  assign receiver_incepts = {TOTAL_BUSES{1'b0}};
  assign receiver_sends = {TOTAL_BUSES{1'b0}};
  assign receiver_streams = {TOTAL_BUSES{1'b0}};
  assign receiver_datas = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
  assign receiver_self_permissions = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
  assign receiver_self_addresses = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
  assign receiver_incept_permissions = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};
  assign receiver_incept_addresses = {(TOTAL_BUSES * WORD_WIDTH){1'b0}};

  core0 #(
    .WORD_MAG(WORD_MAG),
    .UARC_SETS(UARC_SETS),
    .TOTAL_BUSES(TOTAL_BUSES),
    .PROGRAM_ADDR_WIDTH(PROGRAM_ADDR_WIDTH),
    .MAIN_ADDR_WIDTH(MAIN_ADDR_WIDTH),
    .CSTACK_DEPTH(CSTACK_DEPTH),
    .LSTACK_DEPTH(LSTACK_DEPTH),
    .CONVEYOR_ADDR_WIDTH(CONVEYOR_ADDR_WIDTH)
  ) core0 (
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
endmodule
