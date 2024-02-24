
.text

	.global prtdec
	.global prthex
        .global prtnl
        .global strlen
	.global prtchr
	.global prtstr
	.global endprg

	# Word sizes. # Change if a word is not 32 bits, 4 bytes.
	.equ w1, 8
        .equ w2, 16
        .equ w3, 24
        .equ w4, 32
        .equ w5, 40

        .equ w1n, -8
        .equ w2n, -16
        .equ w3n, -24
        .equ w4n, -32
        .equ w5n, -40

# Print a unsigned number to StdOut, in base 10.
# In:  a0 - A number.
# Ret: Nothing.
# Out: A decimal number.
prtdec:
    # Configure stack.
    addi sp, sp, w5n		# Advance sp for stack frame.
    sw ra, 0(sp)                # Save ra.
    sw s1, w1(sp)		# Save s1.
    sw s2, w2(sp)		# Save s2.
    sw s3, w3(sp)		# Save s3.
    sw s4, w4(sp)		# Save s4.

    # Find largest divisor, a power of 10, le the passed number.
    li s1, 10			# Set base.
    li s2, 1			# Init divisor.
prtdec_loop:
    mul t0, s2, s1		# Get next larger divisor.
    beqz t0, prtdec_end_loop	# Check for overflow.
    bgt t0, a0, prtdec_end_loop	# Check for next divisor GT a0.

    mv s2, t0			# Set divisor to next.

    j prtdec_loop
prtdec_end_loop:		# Largest divisor less than a0 in s2.

    # Print each digit, until the divisor is zero.
    mv s3, a0			# Copy a0 into register, to work with.
prtdec_loop2:
    beqz s2, prtdec_end_loop2	# End loop.
    
    divu s4, s3, s2		# Divide passed number by divisor.
    addi t1, s4, '0'		# Get character to print.
    
    la a0, char			# Load addr of string
    sb t1, 0(a0)		# Store character.
    jal prtchr
    
    mul t0, s4, s2		# Get value to subtract from number.
    sub s3, s3, t0		# Get rmainder for next pass.
 
    divu s2, s2, s1		# Divide divisor by base.
    j prtdec_loop2
prtdec_end_loop2:

  # Restore stack.
    lw s4, w4(sp)		# Restore s4.
    lw s3, w3(sp)		# Restore s3.
    lw s2, w2(sp)		# Restore s2.
    lw s1, w1(sp)		# Restore s1.
    lw ra, 0(sp)		# Restore ra.
    addi sp, sp, w5             # Restore sp.

    ret

# Print a unsigned number to StdOut, in base 16.
# In:  a0 - A number.
# Ret: Nothing.
# Out: A hexidecimal number.
prthex:
    # Configure stack.
    addi sp, sp, w5n		# Advance sp for stack frame.
    sw ra, 0(sp)                # Save ra.
    sw s1, w1(sp)		# Save s1.
    sw s2, w2(sp)		# Save s2.
    sw s3, w3(sp)		# Save s3.
    sw s4, w4(sp)		# Save s4.

    mv s3, a0			# Copy a0 into register, to save.

    # Print prefix
    la a0, hprefix		# Load addr of string.
    jal prtstr
    
    # Get largest power of 16, le the passed number.
    li s1, 16			# Set base.
    li s2, 1			# Init divisor.
    
prthex_loop:
    mul t0, s2, s1		# Get next larger divisor.
    beqz t0, prthex_end_loop	# Check for overflow.
    bgt t0, s3, prthex_end_loop	# Check for next divisor GT a0.

    mv s2, t0			# Set divisor to next.

    j prthex_loop
prthex_end_loop:		# Divisor in s2.

prthex_loop2:
    beqz s2, prthex_end_loop2	# End loop when divisor becomes zero.
    
    divu s4, s3, s2		# Divide passed number by divisor.
    
    li t0, 10			# Load cutoff for first letter.
    bge s4, t0, prthex_letr	# Jump to load letter value.
    
    addi t1, s4, '0'		# Get digit value to print.
    j prthex_print_char
    
prthex_letr:
    addi t1, s4, 'A' - 10

prthex_print_char:
    la a0, char			# Load addr of string
    sb t1, 0(a0)		# Store character.
    jal prtchr

    # Prepare for next cycle.
    mul t0, s4, s2		# Get value to subtract from number.
    sub s3, s3, t0		# Get rmainder for next pass.
 
    divu s2, s2, s1		# Divide divisor by base.
    j prthex_loop2

prthex_end_loop2:

    # Restore stack.
    lw s4, w4(sp)		# Restore s4.
    lw s3, w3(sp)		# Restore s3.
    lw s2, w2(sp)		# Restore s2.
    lw s1, w1(sp)		# Restore s1.
    lw ra, 0(sp)		# Restore ra.
    addi sp, sp, w5             # Restore sp.

    ret

# Print a newline.
# In:  Nothing.
# Ret: Nothing.
# Out: Newline to StdOut.
prtnl:
    # Configure stack.
    addi sp, sp, w1n		# Advance sp for stack frame.
    sw ra, 0(sp)                # Save ra.

    addi a0, x0, 1		# StdOut
    la a1, nl			# Load addr of string
    addi a2, x0, 1		# String length
    addi a7, x0, 64		# linux write call
    ecall
    
  # Restore stack.
    lw ra, 0(sp)		# Restore ra.
    addi sp, sp, w1             # Restore sp.

    ret

# Print a character, to StdOut.
# In:  a0 - ptr to a character.
# Ret: Nothing.
# Out: A character.
prtchr:
    # Configure stack.
    addi sp, sp, w1n		# Advance sp for stack frame.
    sw ra, 0(sp)                # Save ra.

    mv a1, a0			# Load addr of character
    addi a0, x0, 1		# StdOut
    addi a2, x0, 1		# String length
    addi a7, x0, 64		# linux write call
    ecall
    
  # Restore stack.
    lw ra, 0(sp)		# Restore ra.
    addi sp, sp, w1             # Restore sp.

    ret

# Print a string, to StdOut.
# In:  a0 - ptr to a zero delimited string.
# Ret: Nothing.
# Out: A string.
prtstr:
    # Configure stack.
    addi sp, sp, w2n	# Advance sp for stack frame.
    sw ra, 0(sp)        # Save ra.
    sw s1, w1(sp)	# Save s1.

    mv s1, a0		# Save ptr to string.
    jal strlen		# String len to a2.
    addi a0, x0, 1	# StdOut
    mv a1, s1		# Load addr of string.
    addi a7, x0, 64	# Linux write.
    ecall

  # Restore stack.
    lw s1, w1(sp)	# Restore s1.
    lw ra, 0(sp)	# Restore ra.
    addi sp, sp, w2     # Restore sp.

    ret

# End program.
# In:  a0 - return code.
# Ret: Nothing.
# Out: Return code.
endprg:
    addi a7, x0, 93	# Service code 93 terminates program.
    ecall

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
char: .ascii " "			# Storage for 1 byte.
nl:   .ascii "\n"
hprefix: .asciz "0x"
