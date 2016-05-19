/// This module defines UARC core0 with an arbitrary bus width.
/// Modifying the bus width will also modify the UARC bus.
/// Any adaptations to smaller or larger buses must be managed externally.
module core0(
  clk,
  reset,
  global,
  senders,
  receivers
  );
  /// The log2 of the word width of the core
  parameter WORD_MAG = 5;
  localparam WORD_WIDTH = 1 << WORD_MAG;
  /// Each set contains WORD_WIDTH amount of buses.
  /// Not all of these buses need to be connected to an actual core.
  parameter UARC_SETS = 1;
  localparam TOTAL_BUSES = UARC_SETS * WORD_WIDTH;

  input clk;
  input reset;
  UARCBus.Global global;
  UARCBus.Sender [TOTAL_BUSES-1:0] senders;
  UARCBus.Receiver [TOTAL_BUSES-1:0] receivers;
endmodule
