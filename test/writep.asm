# Place a value in the immediate location
6 writepi:immval

# Create a tag to the immediate location in memory
imm32 :immval mfill:0,4

# Loop forever
iloop:+
rot0
:+

# Align the program
palign:0xC0,32
