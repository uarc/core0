/// The outgoing bus from a UARC core
///
/// All cores on a synchronous design already share the same clock, so it is not included.
/// The clock domain is the sender's in an asynchronous design.
interface UARCBus #(parameter WIDTH = 32);
  logic enabled;
  /// Signal to kill the core on an enabled bus
  logic kill;
  /// Signal to acknowledge the kill to stop next cycle
  logic kill_ack;
  /// Signal to indicate desire to incept the target
  logic incept;
  /// Signal to acknowledge inception request and allow program transmission
  ///
  /// The first word is accepted the cycle this is asserted and changes next cycle.
  logic incept_ack;
  /// Signal to indicate that a word is being sent
  logic send;
  /// Signal to acknowledge the send (can be asserted the same cycle as send is if possible)
  logic send_ack;
  /// Signal to indicate the intention to send a stream
  logic stream;
  /// Signal to acknowledge the stream transmission
  ///
  /// The first word is accepted the cycle this is asserted and changes next cycle.
  logic stream_ack;

  logic [WIDTH-1:0] data;
  logic [WIDTH-1:0] self_permission;
  logic [WIDTH-1:0] self_address;
  logic [WIDTH-1:0] incept_permission;
  logic [WIDTH-1:0] incept_address;

  modport Global(
    output kill,
    output incept,
    output send,
    output stream,
    output data,
    output self_permission,
    output self_address,
    output incept_permission,
    output incept_address
  );

  modport Sender(
    output enable,
    input kill_ack,
    input incept_ack,
    input send_ack,
    input stream_ack
  );

  modport Receiver(
    input enable,
    input kill,
    output kill_ack,
    input incept,
    output incept_ack,
    input send,
    output send_ack,
    input stream,
    output stream_ack,
    input data,
    input self_permission,
    input self_address,
    input incept_permission,
    input incept_address
  );
endinterface
