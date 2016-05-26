`include "../src/dstack.sv"
`include "../src/stack.sv"
`include "../src/priority_encoder.sv"
`include "../src/alu.sv"
`include "../src/instructions.sv"
`include "../src/jump_immediate_control.sv"
`include "../src/dc_control.sv"

/// This module defines UARC core0 with an arbitrary bus width.
/// Modifying the bus width will also modify the UARC bus.
/// Any adaptations to smaller or larger buses must be managed externally.
module core0(
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

  receiver_enable,
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
  receiver_incept_addresses,
);
  /// The log2 of the word width of the core
  parameter WORD_MAG = 5;
  localparam WORD_WIDTH = 1 << WORD_MAG;
  /// Each set contains WORD_WIDTH amount of buses.
  /// Not all of these buses need to be connected to an actual core.
  parameter UARC_SETS = 1;
  /// Must be less than or equal to UARC_SETS * WORD_WIDTH
  parameter TOTAL_BUSES = 1;
  /// This is the width of the program memory address bus
  parameter PROGRAM_ADDR_WIDTH = 1;
  /// This is the width of the main memory address bus
  parameter MAIN_ADDR_WIDTH = 1;
  /// This is how many recursions are possible with the cstack
  parameter CSTACK_DEPTH = 2;
  /// This is how many loops can be nested with the lstack
  parameter LSTACK_DEPTH = 3;

  input clk;
  input reset;

  // Program memory interface
  output [PROGRAM_ADDR_WIDTH-1:0] programmem_addr;
  input [7:0] programmem_read_value;
  output [WORD_WIDTH-1:0] programmem_write_value;
  output programmem_we;

  // Main memory interface
  output [MAIN_ADDR_WIDTH-1:0] mainmem_read_addr;
  output [MAIN_ADDR_WIDTH-1:0] mainmem_write_addr;
  input [WORD_WIDTH-1:0] mainmem_read_value;
  output [WORD_WIDTH-1:0] mainmem_write_value;
  output mainmem_we;

  // All of the outgoing signals connected to every bus
  output global_kill;
  output global_incept;
  output global_send;
  output global_stream;
  output [WORD_WIDTH-1:0] global_data;
  output [WORD_WIDTH-1:0] global_self_permission;
  output [WORD_WIDTH-1:0] global_self_address;
  output [WORD_WIDTH-1:0] global_incept_permission;
  output [WORD_WIDTH-1:0] global_incept_address;

  // All of the signals for each bus for when this core is acting as the sender
  output [TOTAL_BUSES-1:0] sender_enables;
  input [TOTAL_BUSES-1:0] sender_kill_acks;
  input [TOTAL_BUSES-1:0] sender_incept_acks;
  input [TOTAL_BUSES-1:0] sender_send_acks;
  input [TOTAL_BUSES-1:0] sender_stream_acks;

  // All of the signals for each bus for when this core is acting as the receiver
  input [TOTAL_BUSES-1:0] receiver_enable;
  input [TOTAL_BUSES-1:0] receiver_kills;
  output [TOTAL_BUSES-1:0] receiver_kill_acks;
  input [TOTAL_BUSES-1:0] receiver_incepts;
  output [TOTAL_BUSES-1:0] receiver_incept_acks;
  input [TOTAL_BUSES-1:0] receiver_sends;
  output [TOTAL_BUSES-1:0] receiver_send_acks;
  input [TOTAL_BUSES-1:0] receiver_streams;
  output [TOTAL_BUSES-1:0] receiver_stream_acks;
  input [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_datas;
  input [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_self_permissions;
  input [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_self_addresses;
  input [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_incept_permissions;
  input [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] receiver_incept_addresses;

  // Program counter
  // Stores the PC of the instruction presently being executed
  reg [PROGRAM_ADDR_WIDTH-1:0] pc;
  reg [3:0][MAIN_ADDR_WIDTH-1:0] dcs;
  wire [3:0][MAIN_ADDR_WIDTH-1:0] dc_nexts;
  // Determines the direction of DC writes (0 - post-increment; 1 - pre-decrement)
  reg [3:0] dc_directions;
  // Indicates if this subroutine set the dcs disallowing them to be restored
  reg [3:0] dc_modifies;
  reg [3:0][WORD_WIDTH-1:0] dc_vals;
  // Indicates if a dc was advanced last cycle and a new value must be loaded from memory
  reg dc_reload;
  // Which DC to mutate on the cycle following a DC movement where dc_advance is set
  reg [1:0] dc_mutate;

  // The first bit indicates if the word is finished/complete
  localparam CONVERYOR_WIDTH = 1 + WORD_WIDTH;

  // Conveyors (0 is normal operation and 1 is for interrupts)
  // Note: There must also be two sets of pipelined modules for normal and interrupt mode
  reg [1:0][15:0][CONVERYOR_WIDTH-1:0] conveyors;
  // The head address of the conveyor (it only decrements)
  reg [1:0][3:0] conveyor_heads;

  // Status bits
  reg carry;
  reg overflow;
  reg interrupt;
  reg interrupt_active;

  // UARC bus control bits
  reg [UARC_SETS-1:0][WORD_WIDTH-1:0] bus_selections;
  reg [UARC_SETS-1:0][WORD_WIDTH-1:0] interrupt_enables;
  reg [TOTAL_BUSES-1:0][PROGRAM_ADDR_WIDTH-1:0] interrupt_addresses;

  // The instruction being executed this cycle
  wire [7:0] instruction;
  // The next PC and the address from memory the next instruction will be loaded from
  wire [PROGRAM_ADDR_WIDTH-1:0] pc_next;
  // This is asserted when an immediate jump is to happen
  wire jump_immediate;
  // This is asserted when a stack jump is to happen
  wire jump_stack;
  // This is asserted whenever the call stack is going to be pushed
  wire call;
  // This is asserted whenever the PC is going to jump/move
  wire jump;

  // Signals for the alu
  wire [WORD_WIDTH-1:0] alu_a;
  wire [WORD_WIDTH-1:0] alu_b;
  wire alu_ic;
  wire [2:0] alu_opcode;
  wire [WORD_WIDTH-1:0] alu_out;
  wire alu_oc;
  wire alu_oo;

  // Signals for the dstack
  wire [1:0] dstack_movement;
  wire [WORD_WIDTH-1:0] dstack_next_top;
  wire [WORD_WIDTH-1:0] dstack_top;
  wire [WORD_WIDTH-1:0] dstack_second;
  wire [WORD_WIDTH-1:0] dstack_third;
  wire [5:0] dstack_rot_addr;
  wire [WORD_WIDTH-1:0] dstack_rot_val;
  wire dstack_rotate;
  wire dstack_overflow;

  localparam CSTACK_WIDTH = PROGRAM_ADDR_WIDTH + 4 * (WORD_WIDTH + 2) + 1;

  // Signals for the cstack
  wire cstack_push;
  wire cstack_pop;
  // cstack insert signals
  wire [PROGRAM_ADDR_WIDTH-1:0] cstack_insert_progaddr;
  wire [3:0][WORD_WIDTH-1:0] cstack_insert_dcs;
  wire [3:0] cstack_insert_dc_directions;
  wire [3:0] cstack_insert_dc_modifies;
  wire cstack_insert_interrupt;
  // cstack top signals
  wire [PROGRAM_ADDR_WIDTH-1:0] cstack_top_progaddr;
  wire [3:0][WORD_WIDTH-1:0] cstack_top_dcs;
  wire [3:0] cstack_top_dc_directions;
  wire [3:0] cstack_top_dc_modifies;
  wire cstack_top_interrupt;

  localparam LSTACK_WIDTH = 2 * WORD_WIDTH + 2 * PROGRAM_ADDR_WIDTH;

  // Signals for the lstack
  wire lstack_push;
  wire lstack_pop;
  wire [LSTACK_WIDTH-1:0] lstack_insert;
  wire [2:0][LSTACK_WIDTH-1:0] lstack_tops;
  // lstack registers for active loop
  reg [WORD_WIDTH-1:0] lstack_index;
  reg [WORD_WIDTH-1:0] lstack_total;
  reg [PROGRAM_ADDR_WIDTH-1:0] lstack_beginning;
  reg [PROGRAM_ADDR_WIDTH-1:0] lstack_ending;

  // Signals for the interrupt chooser
  wire [TOTAL_BUSES-1:0] masked_sends;
  wire [WORD_WIDTH-1:0] chosen_send_bus;
  wire chosen_send_on;
  wire interrupt_wait;
  wire [PROGRAM_ADDR_WIDTH-1:0] chosen_interrupt_address;

  // Signals for dc_control
  wire [3:0][MAIN_ADDR_WIDTH-1:0] dc_ctrl_nexts;
  wire [3:0] dc_ctrl_next_directions;
  wire [3:0] dc_ctrl_next_modifies;
  wire dc_ctrl_write;
  wire [MAIN_ADDR_WIDTH-1:0] dc_ctrl_write_address;
  wire dc_ctrl_reload;
  wire [1:0] dc_ctrl_choice;

  genvar i;

  alu #(.WIDTH_MAG(WORD_MAG)) alu(
    .a(alu_a),
    .b(alu_b),
    .ic(alu_ic),
    .opcode(alu_opcode),
    .out(alu_out),
    .oc(alu_oc),
    .oo(alu_oo)
  );

  dstack #(.DEPTH_MAG(7), .WIDTH(WORD_WIDTH)) dstack(
    .next_top(dstack_next_top),
    .top(dstack_top),
    .second(dstack_second),
    .third(dstack_third),
    .rot_addr(dstack_rot_addr),
    .rot_val(dstack_rot_val),
    .rotate(dstack_rotate),
    .overflow(dstack_overflow)
  );

  stack #(.WIDTH(CSTACK_WIDTH), .DEPTH(CSTACK_DEPTH), .VISIBLES(1)) cstack(
    .clk,
    .push(cstack_push),
    .pop(cstack_pop),
    .insert({
      cstack_insert_progaddr,
      cstack_insert_dcs,
      cstack_insert_dc_directions,
      cstack_insert_dc_modifies,
      cstack_insert_interrupt
    }),
    .tops({
      cstack_top_progaddr,
      cstack_top_dcs,
      cstack_top_dc_directions,
      cstack_top_dc_modifies,
      cstack_top_interrupt
    })
  );

  stack #(.WIDTH(LSTACK_WIDTH), .DEPTH(LSTACK_DEPTH), .VISIBLES(3)) lstack(
    .clk,
    .push(lstack_push),
    .pop(lstack_pop),
    .insert(lstack_insert),
    .tops(lstack_tops)
  );

  generate
    for (i = 0; i < TOTAL_BUSES; i = i + 1) begin : CORE0_SEND_MASK_LOOP
      assign masked_sends[i] = interrupt_wait ? (receiver_sends[i] & bus_selections[i/WORD_WIDTH][i%WORD_WIDTH]) :
        (receiver_sends[i] & interrupt_enables[i/WORD_WIDTH][i%WORD_WIDTH]);
    end
  endgenerate

  priority_encoder #(.OUT_WIDTH(WORD_WIDTH), .LINES(TOTAL_BUSES)) chosen_send_priority_encoder(
    .lines(masked_sends),
    .out(chosen_send_bus),
    .on(chosen_send_on)
  );

  dc_control #(.MAIN_ADDR_WIDTH(MAIN_ADDR_WIDTH)) dc_control(
    .instruction,
    .jump_immediate,
    .top(dstack_top[MAIN_ADDR_WIDTH-1:0]),
    .dcs,
    .dc_directions,
    .dc_modifies,
    .dc_nexts(dc_ctrl_nexts),
    .dc_next_directions(dc_ctrl_next_directions),
    .dc_next_modifies(dc_ctrl_next_modifies),
    .write_out(dc_ctrl_write),
    .write_address(dc_ctrl_write_address),
    .reload(dc_ctrl_reload),
    .choice(dc_ctrl_choice)
  );

  jump_immediate_control #(.WORD_WIDTH(WORD_WIDTH)) jump_immediate_control(
    .instruction,
    .top(dstack_top),
    .second(dstack_second),
    .carry,
    .overflow,
    .interrupt,
    .jump_immediate
  );

  assign jump_stack = instruction == `I_CALL || instruction == `I_JMP;
  assign call = instruction == `I_CALLI || instruction == `I_CALL;

  assign instruction = programmem_read_value;

  assign pc_next =
    chosen_send_on ? chosen_interrupt_address :
    jump_immediate ? dc_vals[0] :
    jump_stack ? dstack_top :
    pc + 1;

  assign interrupt_wait = instruction == `I_WAIT;
  assign chosen_interrupt_address = interrupt_addresses[chosen_send_bus];

  always @(posedge clk) begin
    if (reset) begin
      pc <= 0;
      dcs <= 0;
      dc_vals <= 0;
      dc_directions <= 0;
      dc_modifies <= 0;
      dc_reload <= 0;
      conveyors <= 0;
      conveyor_heads <= 0;

      carry <= 0;
      overflow <= 0;
      interrupt <= 0;
      interrupt_active <= 0;
      bus_selections <= 0;
      interrupt_enables <= 0;

      // Initialize the lstack so it would effectively loop over the entire program infinitely
      lstack_index <= 0;
      lstack_total <= ~0;
      lstack_beginning <= 0;
      lstack_ending <= ~0;
    end else begin
      pc <= pc_next;
      dc_mutate <= dc_ctrl_choice;
      dcs <= dc_ctrl_nexts;
      dc_directions <= dc_ctrl_next_directions;
      dc_modifies <= dc_ctrl_next_modifies;
      dc_reload <= dc_ctrl_reload;
      dc_mutate <= dc_ctrl_choice;
    end
  end
endmodule
