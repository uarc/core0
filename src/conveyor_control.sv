`include "../src/instructions.sv"
`include "../src/faults.sv"

module conveyor_control(
  instruction,
  servicing_interrupt,
  interrupt_bus,
  interrupt_value,
  conveyor,
  conveyor_head,
  conveyor_value,
  conveyor_next,
  conveyor_head_next,
  conveyor_back1,
  conveyor_back2,
  halt,
  fault,
);
  parameter WORD_WIDTH = 32;
  localparam FAULT_ADDR_WIDTH = 3;
  localparam TOTAL_FAULTS = 4;
  parameter CONVEYOR_ADDR_WIDTH = 4;
  localparam CONVEYOR_SIZE = 1 << CONVEYOR_ADDR_WIDTH;
  localparam CONVEYOR_WIDTH = 1 + FAULT_ADDR_WIDTH + WORD_WIDTH;
  parameter INTERRUPT_ADDR_WIDTH = 1;

  input [7:0] instruction;
  input servicing_interrupt;
  input [INTERRUPT_ADDR_WIDTH-1:0] interrupt_bus;
  input [WORD_WIDTH-1:0] interrupt_value;
  input [CONVEYOR_SIZE-1:0][CONVEYOR_WIDTH-1:0] conveyor;
  input [CONVEYOR_ADDR_WIDTH-1:0] conveyor_head;
  output [WORD_WIDTH-1:0] conveyor_value;
  output reg [CONVEYOR_SIZE-1:0][CONVEYOR_WIDTH-1:0] conveyor_next;
  output reg [CONVEYOR_ADDR_WIDTH-1:0] conveyor_head_next;
  output [CONVEYOR_ADDR_WIDTH-1:0] conveyor_back1;
  output [CONVEYOR_ADDR_WIDTH-1:0] conveyor_back2;
  output reg halt;
  output reg [FAULT_ADDR_WIDTH-1:0] fault;

  wire [CONVEYOR_ADDR_WIDTH-1:0] conveyor_access;
  wire [CONVEYOR_WIDTH-1:0] conveyor_access_slot;
  wire conveyor_access_finished;
  wire [FAULT_ADDR_WIDTH-1:0] conveyor_access_fault;
  assign conveyor_access = conveyor_head + instruction[3:0];
  assign conveyor_access_slot = conveyor[conveyor_access];
  assign conveyor_value = conveyor_access_slot[WORD_WIDTH-1:0];
  assign conveyor_access_finished = conveyor_access_slot[CONVEYOR_WIDTH-1];
  assign conveyor_access_fault = conveyor_access_slot[CONVEYOR_WIDTH-2:CONVEYOR_WIDTH-1-FAULT_ADDR_WIDTH];

  assign conveyor_back1 = conveyor_access - 1;
  assign conveyor_back2 = conveyor_access - 2;

  always @* begin
    if (servicing_interrupt) begin
      halt = 0;
      fault = `F_NONE;
      conveyor_head_next = conveyor_back2;
    end else begin
      casez (instruction)
        `I_CVZ: begin
          halt = !conveyor_access_finished;
          fault = conveyor_access_fault;
          conveyor_head_next = conveyor_head;
        end
        default: begin
          halt = 0;
          fault = `F_NONE;
          conveyor_head_next = conveyor_back2;
        end
      endcase
    end
  end
endmodule
