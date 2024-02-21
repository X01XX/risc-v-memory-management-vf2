
.text

	.global nu2d
        .global pcr

	# Word sizes. # Change if a word is not 32 bits, 4 bytes.
	.equ w1, 8
        .equ w2, 16
        .equ w3, 24
        .equ w4, 32
        .equ w5, 40
        .equ w6, 48

        .equ w1n, -8
        .equ w2n, -16
        .equ w3n, -24
        .equ w4n, -32
        .equ w5n, -40
        .equ w6n, -48

# Print a unsigned number to StdOut, in base 10.
# In: a0 - A number    
nu2d:
    # Configure stack.
    addi sp, sp, w6n		# Advance sp for stack frame.
    sw ra, 0(sp)                # Save ra.
    sw s1, w1(sp)		# Save s1.
    sw s2, w2(sp)		# Save s2.
    sw s3, w3(sp)		# Save s3.
    sw s4, w4(sp)		# Save s4.
    sw s5, w5(sp)		# Save s5.

    li s1, 10			# Set base.
    li s2, 1			# Init divisor.
loop:
    mul t0, s2, s1		# Get next larger divisor.
    beqz t0, end_loop		# Check for overflow.
    bgt t0, a0, end_loop	# Check for next divisor GT a0.

    mv s2, t0			# Set divisor to next.

    j loop
end_loop:			# Largest divisor less than a0 in s2.

    mv s3, a0			# Copy a0 into register, to save.
loop2:
    beqz s2, end_loop2		# End loop when divisor becomes zero.
    
    divu s4, s3, s2		# Divide passed number by divisor.
    addi s5, s4, '0'		# Get character to print.
    
    addi a0, x0, 1		# StdOut
    la a1, char			# Load addr of string
    sb s5, 0(a1)		# Store character.
    addi a2, x0, 1		# String length
    addi a7, x0, 64		# linux write call
    ecall
    
    mul t0, s4, s2		# Get value to subtract from number.
    sub s3, s3, t0		# Get rmainder for next pass.
 
    divu s2, s2, s1		# Divide divisor by base.
    j loop2
end_loop2:

  # Restore stack.
    lw s5, w5(sp)		# Restore s5.
    lw s4, w4(sp)		# Restore s4.
    lw s3, w3(sp)		# Restore s3.
    lw s2, w2(sp)		# Restore s2.
    lw s1, w1(sp)		# Restore s1.
    lw ra, 0(sp)		# Restore ra.
    addi sp, sp, w6             # Restore sp.

    ret

# Print a carriage return.
pcr:
    # Configure stack.
    addi sp, sp, w1n		# Advance sp for stack frame.
    sw ra, 0(sp)                # Save ra.

    addi a0, x0, 1		# StdOut
    la a1, char			# Load addr of string
    sb s5, 0(a1)		# Store character.
    addi a2, x0, 1		# String length
    addi a7, x0, 64		# linux write call
    ecall
    
  # Restore stack.
    lw ra, 0(sp)		# Restore ra.
    addi sp, sp, w1             # Restore sp.

    ret

.data
char: .word 0			# Storage for 1 byte.
cr:   .ascii "\n"
