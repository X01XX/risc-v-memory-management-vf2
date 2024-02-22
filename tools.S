
.text

	.global nu2d
	.global nu2h
        .global pcr
        .global strlen

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

    # Print 0x
    
    li s1, 10			# Set base.
    li s2, 1			# Init divisor.
nu2d_loop:
    mul t0, s2, s1		# Get next larger divisor.
    beqz t0, nu2d_end_loop	# Check for overflow.
    bgt t0, a0, nu2d_end_loop	# Check for next divisor GT a0.

    mv s2, t0			# Set divisor to next.

    j nu2d_loop
nu2d_end_loop:			# Largest divisor less than a0 in s2.

    mv s3, a0			# Copy a0 into register, to save.
nu2d_loop2:
    beqz s2, nu2d_end_loop2	# End loop when divisor becomes zero.
    
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
    j nu2d_loop2
nu2d_end_loop2:

  # Restore stack.
    lw s5, w5(sp)		# Restore s5.
    lw s4, w4(sp)		# Restore s4.
    lw s3, w3(sp)		# Restore s3.
    lw s2, w2(sp)		# Restore s2.
    lw s1, w1(sp)		# Restore s1.
    lw ra, 0(sp)		# Restore ra.
    addi sp, sp, w6             # Restore sp.

    ret

# Print a unsigned number to StdOut, in base 16.
# In: a0 - A number    
nu2h:
    # Configure stack.
    addi sp, sp, w6n		# Advance sp for stack frame.
    sw ra, 0(sp)                # Save ra.
    sw s1, w1(sp)		# Save s1.
    sw s2, w2(sp)		# Save s2.
    sw s3, w3(sp)		# Save s3.
    sw s4, w4(sp)		# Save s4.
    sw s5, w5(sp)		# Save s5.

    mv s3, a0			# Copy a0 into register, to save.

    # Print prefix
    addi a0, x0, 1		# StdOut
    li a2, 2			# Load string lenght.
    la a1, hprefix		# Load addr of string
    addi a7, x0, 64		# linux write call
    ecall
    
    li s1, 16			# Set base.
    li s2, 1			# Init divisor.
nu2h_loop:
    mul t0, s2, s1		# Get next larger divisor.
    beqz t0, nu2h_end_loop	# Check for overflow.
    bgt t0, s3, nu2h_end_loop	# Check for next divisor GT a0.

    mv s2, t0			# Set divisor to next.

    j nu2h_loop
nu2h_end_loop:			# Largest divisor less than a0 in s2.

nu2h_loop2:
    beqz s2, nu2h_end_loop2	# End loop when divisor becomes zero.
    
    divu s4, s3, s2		# Divide passed number by divisor.
    
    li t0, 10			# Load cutoff for first letter.
    bge s4, t0, nu2h_letr	# Jump to load letter value.
    
    addi s5, s4, '0'		# Get digit value to print.
    j nu2h_print_char
    
nu2h_letr:
    addi s5, s4, 'A' - 10

nu2h_print_char:
    addi a0, x0, 1		# StdOut
    la a1, char			# Load addr of string
    sb s5, 0(a1)		# Store character.
    addi a2, x0, 1		# String length
    addi a7, x0, 64		# linux write call
    ecall
    
    mul t0, s4, s2		# Get value to subtract from number.
    sub s3, s3, t0		# Get rmainder for next pass.
 
    divu s2, s2, s1		# Divide divisor by base.
    j nu2h_loop2
nu2h_end_loop2:

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
    la a1, cr			# Load addr of string
    addi a2, x0, 1		# String length
    addi a7, x0, 64		# linux write call
    ecall
    
  # Restore stack.
    lw ra, 0(sp)		# Restore ra.
    addi sp, sp, w1             # Restore sp.

    ret

# Return the length of a string.
# In:  a0 = ptr to string.
# Ret: a2 = length.
# Note: returns on first non-printable character.
strlen:
    mv t1, a0		# Init byte pointer
    li t2, ' '		# Init lowest character.
    li t3, '~'		# Init highest character.
    li a2, 0		# Init character counter.
    li t4, 10		# Init newline value.

# Loop to check each character.
sl_loop_next:
    lb t0, 0(t1)		# Load a byte.

    beq t0, t4, sl_skip_check	# newline is OK.

    bltu t0, t2, sl_loop_done	# Check for low invalid chacacter.

    bgtu t0, t3, sl_loop_done 	# Check for high invalid character.
sl_skip_check:

    addi t1, t1, 1		# Point at next byte.
    
    addi a2, a2, 1		# Increment the character counter.
    j sl_loop_next

sl_loop_done:
    ret


.data
char: .word 0			# Storage for 1 byte.
cr:   .ascii "\n"
hprefix: .ascii "0x"
