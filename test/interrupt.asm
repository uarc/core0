# Select bus 0
0 slb
# Set the interrupt PC and DC for bus 0
$interrupt iset:interrupt
# Enable interrupts
ien
# Create a loop that will go on effectively forever
-1 loopi:+
continue
:+

# Interrupt tag
:interrupt
# Inside the interrupt, only put an 88 on the stack
88

# Align the segments
alignp:0x3C,32
align:0,8