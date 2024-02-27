# Implement a stack and methods.
#
# See stack struct, below.

.text

# Doubleword sizes:
	.equ d1, 8
	.equ d2, 16
	.equ d3, 24
	.equ d4, 32

	.equ d1n, -8
	.equ d2n, -16
	.equ d4n, -32

	# Shift number bits to convert between words and bytes.
	.equ wbyts, 2
	.equ dbyts, 3

# Struct stack.
	.equ	stack_start,	0	# 8 bytes, 2 words. Ptr to start of stack.
	.equ	stack_end,	8	# 8 bytes, 2 words. stack_start + (wbyts * number items)
	.equ	stack_tos,	16	# 8 bytes, 2 words. Current Top Of Stack.
	.equ	stack_desc,	24	# 8 bytes, 2 words. Ptr to stack name string.
	.equ    stack_words,	8	# Number words in this struct.

# Global labels:
	.global stack_new
	.global stack_push
	.global stack_pop
	.global stack_print
	.global stack_print_name
	.global stack_contains
	
# External labels:
	.extern endprg			# End program.
	.extern strlen			# Load string len into a2.
	.extern prtdec			# Print a number as base 10.
	.extern prthex			# Print a number as base 16.
	.extern prtnl			# Print a newline.
	.extern prtstr			# Print a string.

	.extern mem_alloc		# Get memory from allocate-only memory store.

# Initialize and return a stack.
# mem_init needs to be called from main before calling this.
#
# In:  a0, contains the number of words the stack will need to support.
#      a1, contains a ptr to a string that will name the stack for error messages.
# Ret: a1, a ptr to the memory allocated for the stack (header).
stack_new:
    blez a0, invalid_request 	# Check for zero, or negative, number of words.

    # Configure stack.
    addi sp, sp, d4n		# Advance sp for stack frame.
    sd ra, 0(sp)		# Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.
    sd s3, d3(sp)		# Save s3.

    mv s1, a0			# Save stack number words.
    mv s2, a1			# Save stack decription ptr.

    mv a0, s2
    jal check_name		# Check stack name is OK.

    li a0, stack_words		# Load number of stack struct words.
    jal mem_alloc		# Get stack struct memory ptr into a1.
    mv s3, a1			# Save in stack struct ptr.

    mv a0, s1			# Load stack size.
    jal mem_alloc		# Get stack memory ptr into a1.

    sd a1, stack_start(s3)	# Store stack memory ptr in stack struct.
    sd a1, stack_tos(s3)	# Store stack tos ptr in stack struct.

    slli t2, s1, dbyts		# Multiply number words by word size to get size in bytes.
    add t1, a1, t2		# Add stack number bytes to stack start.
    sd t1, stack_end(s3)	# Store end into stack struct.

    sd s2, stack_desc(s3)	# Store name ptr.

    mv a1, s3			# Load stack struct ptr to return in a1.

    # Restore stack.
    ld s3, d3(sp)		# Restore s3.
    ld s2, d2(sp)		# Restore a0.
    ld s1, d1(sp)		# Return stack struct ptr.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d4		# Restore sp.

    ret				# Return a1

# Display invalid request, then halt.
invalid_request:
    mv s3, a0		# Save number words.

    la a0, invalid_str
    jal prtstr

    mv a0, s3		# Load number words.
    jal prtdec		# Print number as base 10.

    addi a0, x0, 3	# Load return code
    jal endprg

# Push a value onto the a stack.
# In:  a0, ptr to a stack.
#      a1, value to push.
# Ret: Nothing.
stack_push:
    ld t0, stack_tos(a0)	# Load stack tos.

    ld t1, stack_end(a0)	# Load end of stack.

    bgeu t0, t1, stack_full	# Check for stack full.

    sd a1, 0(t0)		# Store the word.

    addi t0, t0, d1		# Point to the next word.

    sd t0, stack_tos(a0)	# Store the new stack ptr value.

    ret

# Display stack full error message, then halt.
stack_full:
    mv s1, a0		# Save stack ptr.

    ld a0, stack_desc(s1)
    jal prtstr

    la a0, sf_str
    jal prtstr

    addi a0, x0, 4	# Load return code
    jal endprg

# Pop a value from the a stack.
# In:  a0, ptr to a stack.
# Ret: a1, value on stack.
stack_pop:
    ld t0, stack_tos(a0)	# Load stack tos.

    ld t1, stack_start(a0)	# Load start of stack.

    # Check for stack empty.
    bleu t0, t1, stack_empty

    addi t0, t0, d1n		# Point to the previous word.
    sd t0, stack_tos(a0)	# Store the new stack ptr.

    ld a1, 0(t0)		# Load the value into a1.

    ret				# Return a1.

# Display stack empty error message, then halt.
stack_empty:
    mv s1, a0		# Save stack ptr.

    ld a0, stack_desc(s1)
    jal prtstr

    la a0, sp_empty_str
    jal prtstr
 
    addi a0, x0, 5	# Load return code
    jal endprg
 
# Check a stack name string, ended with 0, for length and unprintable characters.
# In:  a0 = pointer to string.
# Ret: Nothing.
# Note: Any length GT 0 is OK.
#       No check for a duplicate name with another stack.
check_name:
    lb t0, 0(a0)	# Check for zero length.
    beqz t0, name_too_short

    mv t1, a1		# Init byte pointer
    li t2, ' '
    li t3, '~'

# Loop to check each character.
cn_loop_next:
    lb t0, 0(t1) 		# Load next byte
    beqz t0, cn_loop_done	# Done if zero char found.

    bltu t0, t2, name_invalid_char	# Check for low invalid chacacter.

    bgtu t0, t3, name_invalid_char 	# Check for high invalid character.

    addi t1, t1, 1		# Point at next byte.
    j cn_loop_next

cn_loop_done:
    ret

name_too_short:
    ld a0, cn_err1_str
    jal prtstr

    addi a0, x0, 6	# Load return code
    jal endprg

name_invalid_char:
    ld a0, cn_err2_str
    jal prtstr

    addi a0, x0, 7	# Load return code
    jal endprg

# Print the stack name, to StdOut.
# In:  a0 - Ptr to stack.
# Ret: Nothing.
# Out: Text printed.
stack_print_name:
   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save stack ptr.

    # Print stack name prefix.
    la a0, stack_print_prefix
    jal prtstr

    # Print stack name.
    ld a0, stack_desc(s1)
    jal prtstr

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.
    ret

# Print a stack.
# In:  a0, ptr to a stack struct.
# Ret: Nothing.
# Out: Text printed.
stack_print:
   # Configure stack
    addi sp, sp, d4n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.
    sd s2, d2(sp)	# Save s2.
    sd s3, d3(sp)	# Save s3.

    mv s1, a0		# Save stack ptr.

    jal stack_print_name

    jal prtnl

    la a0, stack_print_num
    jal prtstr

    ld s2, stack_start(s1)	# Load stack start.

    ld s3, stack_end(s1)	# Load stack end.

    sub t3, s3, s2		# Get dif in bytes.
    srli a0, t3, dbyts		# Divide by word bytes.
    jal prtdec			# Print as base 10.

    jal prtnl

    la a0, stack_print_items
    jal prtstr

    ld t1, stack_start(s1)	# Load stack start.
    ld t2, stack_tos(s1)	# Load stack tos.

    sub t0, t2, t1		# Get bytes difference.
    srli a0, t0, dbyts		# Divide by dword bytes.
    jal prtdec			# Print number active items.

    jal prtnl

   # Loop to print eack active item.
    ld s3, stack_tos(s1)	# Load stack tos.
sp_loop_next:
    bgeu s2, s3, sp_loop_end	# Exit loop if at the end of the stack.

    ld a0, 0(s2)    		# load next item
    jal prthex			# Print item in hex.

    jal prtnl

    addi s2, s2, d1		# Point to next item.
    j sp_loop_next
sp_loop_end:

    # Restore stack.
    ld s3, d3(sp)		# Restore s3.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d4		# Restore sp.
    ret

# Check a stack for a value.
# In:  a0, ptr to a stack struct.
#      a1, item to check for.
# Ret: a1 = 1 if true, 0 if false.
stack_contains:
    ld t1, stack_start(a0)	# Load stack start.

    ld t2, stack_tos(a0)	# Load stack end.

    sub t3, t2, t1		# Get dif in bytes.
    srli t3, t3, wbyts		# Divide by word bytes.

sca_loop_next:
    bgeu t1, t2, sca_loop_end	# Exit loop if at the end of the stack.

    ld t0, 0(t1) 		# load next item
    beq t0, a1, sca_true	# Error if item found.

    addi t1, t1, d1		# Point to next item
    j sca_loop_next
sca_loop_end:

    li a1, 0			# Load a1 with false indicator.
    ret

sca_true:
    li a1, 1			# Load a1 with true indicator.
    ret

cn_err1_str:		.asciz "Empty string for stack name?"
invalid_str:    	.asciz "Invalid number of words "
cn_err2_str: 		.asciz "Invalid character in stack name?\n"
stack_print_prefix:	.asciz	"\nStack Name: "
stack_print_num:	.asciz  "Max Items: "
stack_print_items:	.asciz  "Number Available Items: "
sf_str:			.asciz	": stack full\n"
sp_empty_str:		.asciz	": stack empty\n"
