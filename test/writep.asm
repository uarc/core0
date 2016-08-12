# Place a value in the immediate location.
6 writepri:immval
# Wait a cycle or it wont load the new value.
nop
# Create a tag to the immediate location in memory.
imm32 :immval pfill:0,4

# Loop forever.
iloop:+
nop
:+

# Align the program.
palign:0xC0,32
