# Select bus 0
imm8:0 seb
# Set the interrupt PC for bus 0
.interrupt intset
# Enable interrupts
inten
# Create a loop that will go on effectively forever
iloop:+
rot0
:+

# Interrupt tag
:interrupt
# Inside the interrupt, only put an 8 on the stack
imm8:8
return

# Align the program
palign:0xC0,32
