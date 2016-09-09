`include "../src/dstack.sv"
`include "../src/stack.sv"
`include "../src/priority_encoder.sv"
`include "../src/alu.sv"
`include "../src/alu_control.sv"
`include "../src/instructions.sv"
`include "../src/flow_control.sv"
`include "../src/mem_control.sv"
`include "../src/faults.sv"
`include "../src/conveyor_control.sv"
`include "../src/dstack_control.sv"
`include "../src/dc_val_control.sv"
`include "../src/pc_control.sv"

/// This module defines UARC core0 with an arbitrary bus width.
/// Modifying the bus width will also modify the UARC bus.
/// Any adaptations to smaller or larger buses must be managed externally.
module core0(
  clk,
  reset,

  programmem_addr,
  programmem_read_value,
  programmem_write_addess,
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
  /// This is how many DCs fit on the astack
  parameter ASTACK_DEPTH = 8;
  /// This is how many recursions are possible with the cstack
  parameter CSTACK_DEPTH = 2;
  /// This is how many loops can be nested with the lstack
  parameter LSTACK_DEPTH = 3;
  /// Increasing this by 1 doubles the length of the conveyor buffer (dont decrease below 4)
  parameter CONVEYOR_ADDR_WIDTH = 4;

  localparam FAULT_ADDR_WIDTH = 3;
  localparam TOTAL_FAULTS = 5;

  input clk;
  input reset;

  // Program memory interface
  output [PROGRAM_ADDR_WIDTH-1:0] programmem_addr;
  input [(8 + WORD_WIDTH)-1:0] programmem_read_value;
  output [PROGRAM_ADDR_WIDTH-1:0] programmem_write_addess;
  output [WORD_WIDTH/8-1:0] programmem_byte_write_mask;
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
  output reg [WORD_WIDTH-1:0] global_self_permission;
  output reg [WORD_WIDTH-1:0] global_self_address;
  output reg [WORD_WIDTH-1:0] global_incept_permission;
  output reg [WORD_WIDTH-1:0] global_incept_address;

  // All of the signals for each bus for when this core is acting as the sender
  output [TOTAL_BUSES-1:0] sender_enables;
  input [TOTAL_BUSES-1:0] sender_kill_acks;
  input [TOTAL_BUSES-1:0] sender_incept_acks;
  input [TOTAL_BUSES-1:0] sender_send_acks;
  input [TOTAL_BUSES-1:0] sender_stream_acks;

  // All of the signals for each bus for when this core is acting as the receiver
  input [TOTAL_BUSES-1:0] receiver_enables;
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
  reg [3:0][WORD_WIDTH-1:0] dc_vals;
  wire [3:0][WORD_WIDTH-1:0] dc_vals_next;
  // Indicates if a dc was advanced last cycle and a new value must be loaded from memory
  reg dc_reload;
  // Which DC to mutate on the cycle following a DC movement
  reg [1:0] dc_mutate;

  // Status bits
  reg carry;
  reg overflow;
  reg interrupt;
  reg interrupt_active;

  // Fault handlers
  reg [TOTAL_FAULTS-1:0][MAIN_ADDR_WIDTH-1:0] fault_handlers;
  // Determines which fault we are having (if any)
  wire [FAULT_ADDR_WIDTH-1:0] fault;

  // UARC bus control bits
  reg [UARC_SETS-1:0][WORD_WIDTH-1:0] bus_selections;
  reg [UARC_SETS-1:0][WORD_WIDTH-1:0] interrupt_enables;
  reg [TOTAL_BUSES-1:0][PROGRAM_ADDR_WIDTH-1:0] interrupt_addresses;
  wire [TOTAL_BUSES-1:0][PROGRAM_ADDR_WIDTH-1:0] interrupt_addresses_intset;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] bus_selections_set;
  wire [TOTAL_BUSES-1:0][WORD_WIDTH-1:0] bus_selections_sel;

  // The instruction being executed this cycle.
  wire [7:0] instruction;
  // The immediate value (if there is one).
  wire [WORD_WIDTH-1:0] imm;
  // The natural next PC (pc + 1, pc + 2, pc + 3, pc + 5)
  wire [PROGRAM_ADDR_WIDTH-1:0] pc_advance;
  // The next PC assuming no interrupt.
  wire [PROGRAM_ADDR_WIDTH-1:0] pc_next_nointerrupt;
  // The next PC assuming no loop.
  wire [PROGRAM_ADDR_WIDTH-1:0] pc_next_noloop;
  // The actual next PC. Program memory is loaded here.
  wire [PROGRAM_ADDR_WIDTH-1:0] pc_next;
  // This is asserted when the processor is jumping to an absolute location from an immediate value.
  wire jump_immediate;
  // This is asserted when we are branching to a relative location (alu_out).
  wire branch;
  // This is asserted when the processor is jumping to an absolute location from the stack.
  wire jump_stack;
  // This is asserted whenever there is a call.
  wire call;
  // This is asserted whenever we are returning from a call.
  wire returning;
  // This tells the processor to return back to the current instruction on an interrupt.
  wire interrupt_conflict;

  // Soft reset via reset instruction
  wire soft_reset;

  // Signals for the alu
  wire [WORD_WIDTH-1:0] alu_a;
  wire [WORD_WIDTH-1:0] alu_b;
  wire alu_ic;
  wire [3:0] alu_opcode;
  wire [WORD_WIDTH-1:0] alu_out;
  wire alu_oc;
  wire alu_oo;

  // Signals for alu_control
  wire alu_control_store_carry, alu_control_store_overflow;

  // Signals for the dstack
  wire [1:0] dstack_movement;
  wire [WORD_WIDTH-1:0] dstack_next_top;
  wire [WORD_WIDTH-1:0] dstack_top;
  wire [WORD_WIDTH-1:0] dstack_second;
  wire [WORD_WIDTH-1:0] dstack_third;
  wire [4:0] dstack_rot_addr;
  wire [WORD_WIDTH-1:0] dstack_rot_val;
  wire dstack_rotate;
  wire dstack_overflow;
  wire dstack_underflow;

  wire astack_push;
  wire astack_pop;
  wire [MAIN_ADDR_WIDTH-1:0] astack_insert;
  wire [MAIN_ADDR_WIDTH-1:0] astack_top;

  localparam CSTACK_WIDTH = PROGRAM_ADDR_WIDTH + 1;

  // Signals for the cstack
  wire cstack_push;
  wire cstack_pop;
  // cstack insert signals
  wire [PROGRAM_ADDR_WIDTH-1:0] cstack_insert_progaddr;
  wire cstack_insert_interrupt;
  // cstack top signals
  wire [PROGRAM_ADDR_WIDTH-1:0] cstack_top_progaddr;
  wire cstack_top_interrupt;

  // beginning (program) + ending (program) + infinite (flag) + total (word) + index (word)
  localparam LSTACK_WIDTH = 2 * PROGRAM_ADDR_WIDTH + 1 + 2 * WORD_WIDTH;
  localparam LSTACK_DEFAULT =
      {{PROGRAM_ADDR_WIDTH{1'b0}}, {PROGRAM_ADDR_WIDTH{1'b0}}, 1'b1, {WORD_WIDTH{1'b0}}, {WORD_WIDTH{1'b0}}};

  // Signals for the lstack
  wire lstack_push;
  wire lstack_pop;
  wire [LSTACK_WIDTH-1:0] lstack_insert;
  wire [2:0][LSTACK_WIDTH-1:0] lstack_tops;
  // lstack registers for active loop
  reg [WORD_WIDTH-1:0] lstack_index;
  reg [WORD_WIDTH-1:0] lstack_total;
  reg lstack_infinite;
  reg [PROGRAM_ADDR_WIDTH-1:0] lstack_beginning;
  reg [PROGRAM_ADDR_WIDTH-1:0] lstack_ending;
  wire [WORD_WIDTH-1:0] lstack_index_advance;
  wire lstack_next_iter;
  wire lstack_move_beginning;
  // Signals to move to the end of the loop
  wire lstack_move_to_end;
  // Is 1 on a cycle where we are entering a loop that will never run.
  wire lstack_dontloop;
  wire [3:0][WORD_WIDTH-1:0] iterators;

  // Signals for the interrupt chooser
  wire [TOTAL_BUSES-1:0] masked_sends;
  wire [WORD_WIDTH-1:0] chosen_send_bus;
  wire chosen_send_on;
  // Handle actual interrupt (not recv)
  wire handle_interrupt;
  wire interrupt_recv;
  // Any time an interrupt is being serviced at all this cycle
  wire servicing_interrupt;
  wire [PROGRAM_ADDR_WIDTH-1:0] chosen_interrupt_address;
  wire [WORD_WIDTH-1:0] chosen_interrupt_value;

  // Signals for mem_control
  wire [3:0] dc_control_next_directions;
  wire [3:0] dc_control_next_modifies;
  wire dc_control_reload;
  wire [1:0] dc_control_choice;
  wire mem_control_conveyor_memload;
  wire mem_control_dstack_memload;
  reg mem_control_conveyor_memload_last, mem_control_dstack_memload_last;

  localparam CONVEYOR_SIZE = 1 << CONVEYOR_ADDR_WIDTH;
  // The first bit indicates if the word is finished/complete
  localparam CONVEYOR_WIDTH = 1 + FAULT_ADDR_WIDTH + WORD_WIDTH;

  // Signals for conveyor_control
  wire [WORD_WIDTH-1:0] conveyor_value;
  wire [CONVEYOR_ADDR_WIDTH-1:0] conveyor_back1, conveyor_back2;
  wire conveyor_halt;
  wire [FAULT_ADDR_WIDTH-1:0] conveyor_fault;

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

  alu_control #(.WORD_WIDTH(WORD_WIDTH)) alu_control(
    .instruction,
    .imm,
    .top(dstack_top),
    .second(dstack_second),
    .carry,
    .pc({{(WORD_WIDTH-PROGRAM_ADDR_WIDTH){1'b0}}, pc}),
    .pc_advance({{(WORD_WIDTH-PROGRAM_ADDR_WIDTH){1'b0}}, pc_advance}),
    .dcs({
      {{(WORD_WIDTH-MAIN_ADDR_WIDTH){1'b0}}, dcs[3]},
      {{(WORD_WIDTH-MAIN_ADDR_WIDTH){1'b0}}, dcs[2]},
      {{(WORD_WIDTH-MAIN_ADDR_WIDTH){1'b0}}, dcs[1]},
      {{(WORD_WIDTH-MAIN_ADDR_WIDTH){1'b0}}, dcs[0]}
    }),
    .dc_vals(dc_vals_next),
    .alu_a,
    .alu_b,
    .alu_ic,
    .alu_opcode,
    .store_carry(alu_control_store_carry),
    .store_overflow(alu_control_store_overflow)
  );

  dstack #(.DEPTH_MAG(7), .WIDTH(WORD_WIDTH)) dstack(
    .clk,
    .reset(reset || soft_reset),
    .movement(dstack_movement),
    .next_top(dstack_next_top),
    .top(dstack_top),
    .second(dstack_second),
    .third(dstack_third),
    .rot_addr(dstack_rot_addr),
    .rot_val(dstack_rot_val),
    .rotate(dstack_rotate),
    .overflow(dstack_overflow),
    .underflow(dstack_underflow)
  );

  stack #(.WIDTH(MAIN_ADDR_WIDTH), .DEPTH(CSTACK_DEPTH), .VISIBLES(1)) astack(
    .clk,
    .push(astack_push),
    .pop(astack_pop),
    .insert(astack_insert),
    .tops(astack_top)
  );

  assign astack_push = instruction[7:2] == `I_PUSHM;
  assign astack_pop = instruction[7:2] == `I_POPM;
  assign astack_insert = dc_nexts[instruction[1:0]];

  stack #(.WIDTH(CSTACK_WIDTH), .DEPTH(CSTACK_DEPTH), .VISIBLES(1)) cstack(
    .clk,
    .push(cstack_push),
    .pop(cstack_pop),
    .insert({cstack_insert_progaddr, cstack_insert_interrupt}),
    .tops({cstack_top_progaddr, cstack_top_interrupt})
  );

  // Assign signals for cstack
  assign cstack_push = call;
  assign cstack_pop = returning;
  // cstack insert
  assign cstack_insert_progaddr =
    // Interrupts trump all and always return to the address that would have been executed next
    handle_interrupt ? pc_next_nointerrupt :
    // Otherwise calls of various kinds return to the instruction following the present
    pc_advance;
  assign cstack_insert_interrupt = handle_interrupt;

  stack #(.WIDTH(LSTACK_WIDTH), .DEPTH(LSTACK_DEPTH), .VISIBLES(3), .BOTTOM(LSTACK_DEFAULT)) lstack(
    .clk,
    .push(lstack_push),
    .pop(lstack_pop),
    .insert(lstack_insert),
    .tops(lstack_tops)
  );

  // Assign signals for lstack
  assign lstack_push = instruction == `I_ILOOP || (instruction == `I_LOOP && !lstack_dontloop);
  assign lstack_pop = !halt &&
    (instruction == `I_DISCARD || instruction == `I_BREAK || (!lstack_infinite && lstack_index_advance == lstack_total && lstack_next_iter));
  assign lstack_insert = {lstack_beginning, lstack_ending, lstack_infinite, lstack_total, lstack_index};
  assign lstack_index_advance = lstack_index + 1;
  assign lstack_next_iter = !halt &&
      // On an interrupt, we always perform the next iteration on return from the interrupt.
      // Loops have higher precendence than return, so returning from an interrupt can go to the beginning of the loop.
      (instruction == `I_CONTINUE || (pc_next_noloop == lstack_ending && !handle_interrupt));
  assign lstack_move_beginning = lstack_next_iter && !lstack_pop;
  assign lstack_move_to_end = lstack_pop && instruction != `I_DISCARD;
  assign lstack_dontloop = instruction == `I_LOOP && dstack_top == {WORD_WIDTH{1'b0}};
  assign iterators[0] = lstack_index;
  assign iterators[1] = lstack_tops[0][WORD_WIDTH-1:0];
  assign iterators[2] = lstack_tops[1][WORD_WIDTH-1:0];
  assign iterators[3] = lstack_tops[2][WORD_WIDTH-1:0];

  generate
    for (i = 0; i < TOTAL_BUSES; i = i + 1) begin : CORE0_SEND_MASK_LOOP
      assign masked_sends[i] = receiver_enables[i] & (
          interrupt_recv ?
            (receiver_sends[i] & bus_selections[i/WORD_WIDTH][i%WORD_WIDTH]) :
            (receiver_sends[i] & interrupt_enables[i/WORD_WIDTH][i%WORD_WIDTH])
        );

      assign interrupt_addresses_intset[i] = bus_selections[i/WORD_WIDTH][i%WORD_WIDTH] ?
        dstack_top[PROGRAM_ADDR_WIDTH-1:0] : interrupt_addresses[i];

      assign bus_selections_set[i] = (i / WORD_WIDTH == dstack_top) ? dstack_second[i % WORD_WIDTH] : 1'b0;
    end
  endgenerate

  assign bus_selections_sel = bus_selections_set | bus_selections;

  priority_encoder #(.OUT_WIDTH(WORD_WIDTH), .LINES(TOTAL_BUSES)) chosen_send_priority_encoder(
    .lines(masked_sends),
    .out(chosen_send_bus),
    .on(chosen_send_on)
  );

  mem_control #(.MAIN_ADDR_WIDTH(MAIN_ADDR_WIDTH), .WORD_WIDTH(WORD_WIDTH)) mem_control(
    .reset(reset || soft_reset),
    .instruction,
    .top(dstack_top),
    .second(dstack_second),
    .alu_out(alu_out[MAIN_ADDR_WIDTH-1:0]),
    .astack_top,
    // TODO: Make stream controller.
    .stream_in(1'b0),
    .stream_in_value({WORD_WIDTH{1'bx}}),
    .stream_out(1'b0),
    .stream_address({MAIN_ADDR_WIDTH{1'bx}}),
    .conveyor_memload_last(mem_control_conveyor_memload_last),
    .dstack_memload_last(mem_control_dstack_memload_last),
    .dcs,
    .dc_nexts,
    .write_out(mainmem_we),
    .write_address(mainmem_write_addr),
    .write_value(mainmem_write_value),
    .read_address(mainmem_read_addr),
    .conveyor_memload(mem_control_conveyor_memload),
    .dstack_memload(mem_control_dstack_memload),
    .reload(dc_control_reload),
    .choice(dc_control_choice)
  );

  dc_val_control #(.WORD_WIDTH(WORD_WIDTH)) dc_val_control(
    .instruction,
    .imm,
    .top(dstack_top),
    .second(dstack_second),
    .dc_vals,
    .dc_reload,
    .dc_mutate,
    .mem_in(mainmem_read_value),
    .dc_vals_next
  );

  flow_control #(.WORD_WIDTH(WORD_WIDTH), .TOTAL_BUSES(TOTAL_BUSES)) flow_control(
    .instruction,
    .top(dstack_top),
    .second(dstack_second),
    .lstack_dontloop,
    .carry,
    .overflow,
    .interrupt,
    .receiver_sends,
    .jump_immediate,
    .jump_stack,
    .branch
  );

  conveyor_control #(.WORD_WIDTH(WORD_WIDTH), .CONVEYOR_ADDR_WIDTH(CONVEYOR_ADDR_WIDTH)) conveyor_control(
    .clk,
    .reset(reset || soft_reset),
    .instruction,
    .interrupt_active,
    .handle_interrupt,
    .servicing_interrupt,
    .interrupt_bus(chosen_send_bus),
    .interrupt_value(chosen_interrupt_value),
    .load_last(mem_control_conveyor_memload_last),
    .mem_in(mainmem_read_value),
    .conveyor_value,
    .conveyor_back1,
    .conveyor_back2,
    .halt(conveyor_halt),
    .fault(conveyor_fault)
  );

  dstack_control #(.WORD_WIDTH(WORD_WIDTH), .TOTAL_BUSES(TOTAL_BUSES)) dstack_control (
    .instruction,
    .imm,
    .halt,
    .dcs({
      {{(WORD_WIDTH-MAIN_ADDR_WIDTH){1'b0}}, dcs[3]},
      {{(WORD_WIDTH-MAIN_ADDR_WIDTH){1'b0}}, dcs[2]},
      {{(WORD_WIDTH-MAIN_ADDR_WIDTH){1'b0}}, dcs[1]},
      {{(WORD_WIDTH-MAIN_ADDR_WIDTH){1'b0}}, dcs[0]}
    }),
    .dc_vals(dc_vals_next),
    .iterators,
    .top(dstack_top),
    .second(dstack_second),
    .third(dstack_third),
    .alu_out,
    .mem_in(mainmem_read_value),
    .self_perimission(global_self_permission),
    .self_address(global_self_address),
    .receiver_self_permissions,
    .receiver_self_addresses,
    .conveyor_value,
    .rotate_value(dstack_rot_val),
    .movement(dstack_movement),
    .next_top(dstack_next_top),
    .rotate(dstack_rotate),
    .rotate_addr(dstack_rot_addr)
  );

  pc_control #(.WORD_WIDTH(WORD_WIDTH), .PROGRAM_ADDR_WIDTH(PROGRAM_ADDR_WIDTH)) pc_control (
    .instruction,
    .pc,
    .pc_advance
  );

  assign sender_enables = bus_selections;

  assign call =
    instruction == `I_CALLI ||
    instruction == `I_CALLRI ||
    instruction == `I_CALL ||
    handle_interrupt ||
    fault != `F_NONE;
  assign returning = instruction == `I_RETURN;

  assign {imm, instruction} = programmem_read_value;
  // Whatever fault we will service next instruction (none if F_NONE)
  // TODO: Potentially add F_SEGFAULT by extending all memory addresses to word width and checking for bounds
  // or reserve F_SEGFAULT for memory management extension
  assign fault =
    dstack_overflow ? `F_DATA_STACK_OVERFLOW :
    dstack_underflow ? `F_DATA_STACK_UNDERFLOW :
    conveyor_fault;

  assign pc_next_noloop =
    halt ? pc :
    fault != `F_NONE ? fault_handlers[fault] :
    returning ? cstack_top_progaddr :
    jump_immediate ? imm[PROGRAM_ADDR_WIDTH-1:0] :
    jump_stack ? dstack_top[PROGRAM_ADDR_WIDTH-1:0] :
    branch ? alu_out[PROGRAM_ADDR_WIDTH-1:0] :
    pc_advance;
  assign pc_next_nointerrupt =
    lstack_move_to_end ? lstack_ending :
    lstack_next_iter ? lstack_beginning :
    pc_next_noloop;
  assign pc_next = reset ? {PROGRAM_ADDR_WIDTH{1'b0}} :
    handle_interrupt ? chosen_interrupt_address : pc_next_nointerrupt;
  assign programmem_addr = pc_next;

  assign handle_interrupt = chosen_send_on && !interrupt_active && !interrupt_recv;
  assign interrupt_recv = instruction == `I_INTRECV;
  assign servicing_interrupt = chosen_send_on && !interrupt_active;
  assign chosen_interrupt_address = interrupt_addresses[chosen_send_bus];
  assign chosen_interrupt_value = receiver_datas[chosen_send_bus];

  assign halt =
    ((interrupt_recv || instruction == `I_INTWAIT) && !chosen_send_on) ||
    // Wait until all enabled buses are acknowledging, then we can move to the next instruction.
    (global_send && sender_enables != sender_send_acks) ||
    mem_control_dstack_memload ||
    conveyor_halt;

  // TODO: Separate this into its own module for readability.
  assign programmem_byte_write_mask =
      (instruction == `I_WRITEPO || instruction == `I_WRITEPORI) ? {{(WORD_WIDTH/8-1){1'b0}}, 1'b1} :
      (instruction == `I_WRITEPS || instruction == `I_WRITEPSRI) ? {{(WORD_WIDTH/8-2){1'b0}}, 2'b11} :
      {(WORD_WIDTH/8){1'b1}};
  assign programmem_write_value =
      instruction == `I_WRITEPI ? dstack_top :
      instruction == `I_WRITEPRI ? dstack_top :
      instruction == `I_WRITEPORI ? dstack_top :
      instruction == `I_WRITEPSRI ? dstack_top :
      dstack_second;
  assign programmem_we =
      instruction == `I_WRITEP ||
      instruction == `I_WRITEPO ||
      instruction == `I_WRITEPS ||
      instruction == `I_WRITEPI ||
      instruction == `I_WRITEPRI ||
      instruction == `I_WRITEPORI ||
      instruction == `I_WRITEPSRI;
  assign programmem_write_addess =
      instruction == `I_WRITEPI ? imm[PROGRAM_ADDR_WIDTH-1:0] :
      instruction == `I_WRITEPRI ? alu_out[PROGRAM_ADDR_WIDTH-1:0] :
      instruction == `I_WRITEPORI ? alu_out[PROGRAM_ADDR_WIDTH-1:0] :
      instruction == `I_WRITEPSRI ? alu_out[PROGRAM_ADDR_WIDTH-1:0] :
      dstack_top[PROGRAM_ADDR_WIDTH-1:0];

  assign global_kill = 1'b0;
  assign global_incept = 1'b0;
  assign global_send = instruction == `I_INTSEND;
  assign global_stream = 1'b0;
  assign global_data = global_send ? dstack_top : {WORD_WIDTH{1'bx}};
  assign receiver_kill_acks = {TOTAL_BUSES{1'b0}};
  assign receiver_incept_acks = {TOTAL_BUSES{1'b0}};
  assign receiver_send_acks = servicing_interrupt << chosen_send_bus;
  assign receiver_stream_acks = {TOTAL_BUSES{1'b0}};

  assign soft_reset = instruction == `I_RESET;

  always @(posedge clk) begin
    pc <= pc_next;
    if (reset || soft_reset) begin
      dcs <= 0;
      dc_vals <= 0;
      dc_mutate <= 0;
      dc_reload <= 1'b1;

      carry <= 0;
      overflow <= 0;
      interrupt <= 0;
      fault_handlers <= 0;
      interrupt_active <= 0;
      bus_selections <= 0;
      interrupt_enables <= 0;

      // Initialize the lstack so it would effectively loop over the entire program infinitely
      {lstack_beginning, lstack_ending, lstack_infinite, lstack_total, lstack_index} <= LSTACK_DEFAULT;
      mem_control_conveyor_memload_last <= 0;
      mem_control_dstack_memload_last <= 0;

      // Initialize the global self permission
      global_self_permission <= 0;
    end else begin
      dcs <= dc_nexts;
      dc_vals <= dc_vals_next;
      dc_reload <= dc_control_reload;
      dc_mutate <= dc_control_choice;
      if (handle_interrupt) begin
        interrupt_active <= 1'b1;
        // Clear these so they get reloaded again when we return from the interrupt
        // This only matters if they would have otherwise been set to 1
        mem_control_conveyor_memload_last <= 1'b0;
        mem_control_dstack_memload_last <= 1'b0;
      end else begin
        mem_control_conveyor_memload_last <= mem_control_conveyor_memload;
        mem_control_dstack_memload_last <= mem_control_dstack_memload;
      end
      // On the exit of an interrupt, switch back to the normal state and pipelines
      if (returning && cstack_top_interrupt)
          interrupt_active <= 1'b0;
      // lstack top is stored in this module so manually handle the pop case
      if (lstack_pop)
        {lstack_beginning, lstack_ending, lstack_infinite, lstack_total, lstack_index} <= lstack_tops[0];
      else if (lstack_next_iter)
        lstack_index <= lstack_index_advance;
      // Store carry when instructions produce it
      if (alu_control_store_carry)
        carry <= alu_oc;
      // Store overflow when instructions produce it
      if (alu_control_store_overflow)
        overflow <= alu_oo;

      // Handle instruction specific state changes
      casez (instruction)
        `I_INTEN: interrupt_enables <= bus_selections;
        `I_INTSET: begin
          interrupt_addresses <= interrupt_addresses_intset;
        end
        `I_SEB: bus_selections <= (1'b1 << dstack_top);
        `I_SLB: bus_selections[dstack_top] <= 1'b1;
        `I_USB: bus_selections[dstack_top] <= 1'b0;
        `I_SET: bus_selections <= bus_selections_set;
        `I_SEL: bus_selections <= bus_selections_sel;
        `I_ILOOP: begin
          lstack_beginning <= pc_advance;
          lstack_ending <= alu_out[PROGRAM_ADDR_WIDTH-1:0];
          lstack_infinite <= 1'b1;
          // Specify that it should actually wrap around at the maximum integer.
          lstack_total <= {WORD_WIDTH{1'b0}};
          lstack_index <= 0;
        end
        `I_SETPA: begin
          global_incept_permission <= dstack_second;
          global_incept_address <= dstack_top;
        end
        `I_LOOP: begin
          lstack_beginning <= pc_advance;
          lstack_ending <= alu_out[PROGRAM_ADDR_WIDTH-1:0];
          lstack_infinite <= 1'b0;
          lstack_total <= dstack_top;
          lstack_index <= 0;
        end
        `I_SEF: fault_handlers[dstack_top] <= dstack_second;
        default: ;
      endcase
    end
  end
endmodule
