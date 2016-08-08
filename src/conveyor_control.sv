`include "../src/instructions.sv"
`include "../src/faults.sv"

module conveyor_control(
  clk,
  reset,
  instruction,
  interrupt_active,
  handle_interrupt,
  servicing_interrupt,
  interrupt_bus,
  interrupt_value,
  load_last,
  mem_in,
  conveyor_value,
  conveyor_back1,
  conveyor_back2,
  halt,
  fault
);
  parameter WORD_WIDTH = 32;
  localparam FAULT_ADDR_WIDTH = 3;
  localparam TOTAL_FAULTS = 4;
  parameter CONVEYOR_ADDR_WIDTH = 4;
  localparam CONVEYOR_SIZE = 1 << CONVEYOR_ADDR_WIDTH;
  localparam CONVEYOR_WIDTH = 1 + FAULT_ADDR_WIDTH + WORD_WIDTH;

  input clk, reset;
  input [7:0] instruction;
  input interrupt_active;
  input handle_interrupt;
  input servicing_interrupt;
  input [WORD_WIDTH-1:0] interrupt_bus;
  input [WORD_WIDTH-1:0] interrupt_value;
  input load_last;
  input [WORD_WIDTH-1:0] mem_in;
  // The output of the value at the conveyor_access location
  output [WORD_WIDTH-1:0] conveyor_value;
  // The back addresses get used in pipelines and other modules to add stuff to the conveyor
  output [CONVEYOR_ADDR_WIDTH-1:0] conveyor_back1;
  output [CONVEYOR_ADDR_WIDTH-1:0] conveyor_back2;
  output reg halt;
  output reg [FAULT_ADDR_WIDTH-1:0] fault;

  reg [CONVEYOR_SIZE-1:0][CONVEYOR_WIDTH-1:0] conveyors [0:1];
  reg [CONVEYOR_ADDR_WIDTH-1:0] conveyor_heads [0:1];

  wire [CONVEYOR_SIZE-1:0][CONVEYOR_WIDTH-1:0] active_conveyor;
  wire [CONVEYOR_WIDTH-1:0] conveyor_access_slot;
  wire [CONVEYOR_ADDR_WIDTH-1:0] conveyor_head;
  wire [CONVEYOR_ADDR_WIDTH-1:0] conveyor_access;
  wire conveyor_access_finished;
  wire [FAULT_ADDR_WIDTH-1:0] conveyor_access_fault;

  wire interrupt_conveyor_active;
  assign interrupt_conveyor_active = interrupt_active || handle_interrupt;

  assign active_conveyor = conveyors[interrupt_conveyor_active];
  assign conveyor_head = conveyor_heads[interrupt_conveyor_active];
  assign conveyor_access = conveyor_head + instruction[3:0];
  assign conveyor_access_slot = (load_last && conveyor_access == conveyor_head) ?
    {1'b1, `F_NONE, mem_in} : active_conveyor[conveyor_access];
  assign conveyor_value = conveyor_access_slot[WORD_WIDTH-1:0];
  assign conveyor_access_finished = conveyor_access_slot[CONVEYOR_WIDTH-1];
  assign conveyor_access_fault = conveyor_access_slot[CONVEYOR_WIDTH-2:CONVEYOR_WIDTH-1-FAULT_ADDR_WIDTH];

  assign conveyor_back1 = conveyor_head - 1;
  assign conveyor_back2 = conveyor_head - 2;

  always @* begin
    // Even if there is an interrupt, we need to indicate halt so it knows which instruction to return to
    casez (instruction)
      `I_CVZ: begin
        halt = !conveyor_access_finished;
        fault = conveyor_access_fault;
      end
      // TODO: Eventually, resolve this to not be a conflict at all.
      `I_READ: begin
        // The architecture does not permit loading into the non-active conveyor after an interrupt happens
        // Due to this the instruction needs to be stalled so it is ran again after the interrupt
        halt = handle_interrupt;
        fault = `F_NONE;
      end
      `I_REREADIZ: begin
        // The architecture does not permit loading into the non-active conveyor after an interrupt happens
        // Due to this the instruction needs to be stalled so it is ran again after the interrupt
        halt = handle_interrupt;
        fault = `F_NONE;
      end
      `I_REREADZ: begin
        // The architecture does not permit loading into the non-active conveyor after an interrupt happens
        // Due to this the instruction needs to be stalled so it is ran again after the interrupt
        halt = handle_interrupt;
        fault = `F_NONE;
      end
      default: begin
        halt = 1'b0;
        fault = `F_NONE;
      end
    endcase
  end

  always @(posedge clk) begin
    if (reset) begin
      for (int i = 0; i < CONVEYOR_SIZE; i++) begin
        conveyors[0][i] <= {1'b0, `F_NONE, {WORD_WIDTH{1'b0}}};
        conveyors[1][i] <= {1'b0, `F_NONE, {WORD_WIDTH{1'b0}}};
      end
      conveyor_heads[0] <= 0;
      conveyor_heads[1] <= 0;
    end else begin
      if (load_last) begin
        if (interrupt_active) begin
          conveyors[1][conveyor_heads[1]] <= {1'b1, `F_NONE, mem_in};
        end else begin
          conveyors[0][conveyor_heads[0]] <= {1'b1, `F_NONE, mem_in};
        end
      end else if (handle_interrupt) begin
        conveyors[1][conveyor_back1] <= {1'b1, `F_NONE, interrupt_value};
        conveyors[1][conveyor_back2] <= {1'b1, `F_NONE, interrupt_bus};
        conveyor_heads[1] <= conveyor_back2;
      end else if (servicing_interrupt) begin
        conveyors[0][conveyor_back1] <= {1'b1, `F_NONE, interrupt_value};
        conveyors[0][conveyor_back2] <= {1'b1, `F_NONE, interrupt_bus};
        conveyor_heads[0] <= conveyor_back2;
      end else begin
        casez (instruction)
          `I_READ: conveyor_heads[interrupt_active] <= conveyor_back1;
          `I_REREADIZ: conveyor_heads[interrupt_active] <= conveyor_back1;
          `I_REREADZ: conveyor_heads[interrupt_active] <= conveyor_back1;
        endcase
      end
    end
  end
endmodule
