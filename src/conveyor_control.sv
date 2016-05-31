`include "../src/instructions.sv"
`include "../src/faults.sv"

module conveyor_control(
  clk,
  reset,
  instruction,
  interrupt_active,
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

  reg [1:0][CONVEYOR_SIZE-1:0][CONVEYOR_WIDTH-1:0] conveyors;
  reg [1:0][CONVEYOR_ADDR_WIDTH-1:0] conveyor_heads;

  wire [CONVEYOR_SIZE-1:0][CONVEYOR_WIDTH-1:0] active_conveyor;
  wire [CONVEYOR_WIDTH-1:0] conveyor_access_slot;
  wire [CONVEYOR_ADDR_WIDTH-1:0] conveyor_access;
  wire conveyor_access_finished;
  wire [FAULT_ADDR_WIDTH-1:0] conveyor_access_fault;

  assign active_conveyor = conveyors[interrupt_active];
  assign conveyor_head = conveyor_heads[interrupt_active];
  assign conveyor_access = conveyor_head + instruction[3:0];
  assign conveyor_access_slot = active_conveyor[conveyor_access];
  assign conveyor_value = conveyor_access_slot[WORD_WIDTH-1:0];
  assign conveyor_access_finished = conveyor_access_slot[CONVEYOR_WIDTH-1];
  assign conveyor_access_fault = conveyor_access_slot[CONVEYOR_WIDTH-2:CONVEYOR_WIDTH-1-FAULT_ADDR_WIDTH];

  assign conveyor_back1 = conveyor_access - 1;
  assign conveyor_back2 = conveyor_access - 2;

  always @* begin
    // Even if there is an interrupt, we need to indicate halt so it knows which instruction to return to
    casez (instruction)
      `I_CVZ: begin
        halt = !conveyor_access_finished;
        fault = conveyor_access_fault;
      end
      default: begin
        halt = 0;
        fault = `F_NONE;
      end
    endcase
  end

  always @(posedge clk) begin
    if (reset) begin
      conveyors <= 0;
      conveyor_heads <= 0;
    end else if (load_last) begin
      if (interrupt_active) begin
        conveyors[1][conveyor_back1] <= {1'b1, `F_NONE, mem_in};
        conveyor_heads[1] <= conveyor_back1;
      end else begin
        conveyors[0][conveyor_back1] <= {1'b1, `F_NONE, mem_in};
        conveyor_heads[0] <= conveyor_back1;
      end
    end else if (servicing_interrupt) begin
      conveyors[0][conveyor_back1] <= {1'b1, `F_NONE, interrupt_value};
      conveyors[0][conveyor_back2] <= {1'b1, `F_NONE, interrupt_bus};
      conveyor_heads[0] <= conveyor_back2;
    end
  end
endmodule
