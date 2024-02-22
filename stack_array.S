# Implement a stack-array and methods.
#
# Run stack_array_new to allocate, and initialize, memory for a new stack_array.
#
# Run stack_array_alloc, to get an address to an available array item.
#
# Run stack_array_dealloc, to return an address that is no longer used.
#
#    There are two sections of code in stack_array_dealloc that can be commented out,
#    for greater speed, but lower detection of errors.
#
#     It does not check for invalid addresses, being deallocated, but that can be done by the caller.
#
# See stack_array struct, below.

# Word sizes. Change if a word is not 32 bits, 4 bytes.
	.equ w1, 8
	.equ w2, 16
	.equ w3, 24
	.equ w4, 32
	.equ w5, 40
	.equ w6, 48
	.equ w7, 56
	.equ w8, 64
	.equ w1n, -8
	.equ w2n, -16
	.equ w3n, -24
	.equ w8n, -64

	# Shift number bits to convert between words and bytes.
	# Change if a word is not 32 bits, 4 bytes.
	.equ sbts, 3

# Struct stack_array (sa):
	.equ	sa_stack_ptr, 0		# Ptr to stack struct.
	.equ 	sa_array_ptr, w1	# Ptr to array.
	.equ	sa_num_items, w2	# Max number items.
	.equ	sa_item_words, w3	# Number words per item.
	.equ	sa_words, 4		# Number words in this struct.

# Global labels:
	.global stack_array_new
	.global stack_array_dealloc
	.global stack_array_alloc
	.global stack_array_print

# External labels:
	.extern mem_alloc		# Get memory from allocate-only memory store.

	.extern stack_new
	.extern stack_push
	.extern stack_pop
	.extern stack_print
	.extern stack_print_name
	.extern stack_contains
	.extern nu2h

# Generate a stack-array
# mem_init needs to be called from main before calling this.
#
# In:  a0 - Number of items.
#      a1 - Number of words in each item.
#      a2 - Pointer to string description.
# Ret: a1 - Stack pointer.
#      The stack is loaded with the ptr to each array item.
#      The array ptr is not needed by the caller, it is only used in this function.
stack_array_new:
    blez a0, invalid_num_items # Check for zero, or negative, number of items.
    blez a1, invalid_num_words # Check for zero, or negative, number of words.

    # Configure stack.
    addi sp, sp, w8n	# Advance sp for stack frame.
    sw ra, 0(sp)	# Save return addr.
    sw s1, w1(sp)	# Save s1.
    sw s2, w2(sp)	# Save s2.
    sw s3, w3(sp)	# Save s3 
    sw s4, w4(sp)	# Save s4.
    sw s5, w5(sp)	# Save s5.
    sw s6, w6(sp)	# Save s6.
    sw s7, w7(sp)	# Save s7.

    mv s1, a0		# Save number items.
    mv s2, a1		# Save number words per item.
    mv s3, a2		# Save ptr to description.

    # Allocate sa struct.
    li	a0, sa_words	# Load number words in SA struct.
    jal mem_alloc	# Get ptr to array into a1.
    mv s7, a1		# Save sa struct ptr.

    # Add number items to struct.
    sw s1, sa_num_items(s7)

    # Add words per item, to struct.
    sw s2, sa_item_words(s7)

    # Allocate new stack.
    mv	a0, s1		# Load number of items.
    mv	a1, s3		# Load ptr to description.
    jal stack_new	# Get ptr to stack in a1.

    # Save stack struct ptr to SA struct.
    sw  a1, sa_stack_ptr(s7)
	
    # Allocate array.

    # Calc array words.  Use additions to stay withn RV32I, RV64I, .. ?
    mv	t0, s1		# Load number of items.
    mv	t1, s2		# Load number of words in each item.
#   mul a0, s1, s2	# Get number of words of array memory needed.
    li a0, 0		# Init counter.
top_mult:
    beqz t0, end_mult	# Check for end.
    add a0, a0, t1	# Add the number of words in one item.
    addi t0, t0, -1	# Decrement counter.
    jal top_mult	# Jump to add next item number words.
end_mult:
    jal mem_alloc	# a0 contains number words needed.  Get memory allocation for array into a1.

    # Save array ptr to struct.
    sw  a1, sa_array_ptr(s7)
	
    # Push the ptr to each array item onto the stack.

    # Load ptrs to stack and array.
    lw	s4, sa_stack_ptr(s7)	# Load ptr to stack.

    lw	s5, sa_array_ptr(s7)	# Load ptr to array.

    # Calc number bytes per item.
    mv	 s6, s2			# Load number of words in each item.
    slli s6, s6, sbts           # Multiply number words by word size to get size in bytes.

loop:
    # Push next item ptr to stack.  Need a0, ptr to stack, a1 value to push.
    mv a0, s4		# Load stack ptr for call.
    mv a1, s5		# Load array item ptr for call.
    jal stack_push
    
    # Check if done.
    addi s1, s1, -1	# Decrement number items.
    beqz s1, ret	# Return if zero, no items left.
    
    add s5, s5, s6	# Point to next array item.

    j loop

ret:
    mv a1, s7		# Load sa ptr to return.

    # Cleanup stack.
    lw s1, w1(sp)	# Restore s1.
    lw s2, w2(sp)	# Restore s2.
    lw s3, w3(sp)	# Restore s3.
    lw s4, w4(sp)	# Restore s4.
    lw s5, w5(sp)	# Restore s5.
    lw s6, w6(sp)	# Restore s6.
    lw s7, w7(sp)	# Restore s7.
    lw ra, 0(sp)	# Restore ra.
    addi sp, sp, w8	# Restore sp.

    ret			# Return a1


# Print a stack_array.
# In:  a0 - stack_array ptr.
# Ret: Nothing.
# Out: Text to StdOut.
stack_array_print:
    addi sp, sp, w2n	# Advance sp for stack frame.
    sw ra, 0(sp)	# Save ra.
    sw s1, w1(sp)	# Save s1.

    mv s1, a0		# sa struct adr to s1.

    # Print stack_array address prefix.
    la a0, sa_adr_str	# Load addr of prefix string.
    jal strlen		# String len to a2.
    addi a0, x0, 1	# StdOut
    la a1, sa_adr_str	# Load addr of prefix string.
    addi a7, x0, 64	# Linux write.
    ecall

    # Print stack_array address.
    mv a0, s1
    jal nu2h		# Print addr.

    # Print stack address prefix.
    la a0, stk_adr_str
    jal strlen		# String len to a2.
    addi a0, x0, 1	# StdOut
    la a1, stk_adr_str	# Load addr of prefix string.
    addi a7, x0, 64	# Linux write.
    ecall

    # Print stack address.
    lw a0, sa_stack_ptr(s1)
    jal nu2h

    # Print stack.
    lw a0, sa_stack_ptr(s1)
    jal stack_print
    
    # Print array address prefix.
    la a0, ary_adr_str
    jal strlen		# String len to a2.
    addi a0, x0, 1	# StdOut
    la a1, ary_adr_str	# Load addr of prefix string.
    addi a7, x0, 64	# Linux write.
    ecall

    # Print array address.
    lw a0, sa_array_ptr(s1)
    jal nu2h

    jal pcr

    # Cleanup stack.
    lw ra, 0(sp)	# Restore ra.
    lw s1, w1(sp)	# Restore s1.
    addi sp, sp, w2	# Restare sp.

    ret

# Display invalid request, then halt.
invalid_num_items:
    la a0, invalid_num_items_str
    jal strlen		# String len to a2.
    addi a0, x0, 1	# StdOut
    la a1, invalid_num_items_str	# Load addr of prefix string.
    addi a7, x0, 64	# Linux write.
    ecall

    addi a0, x0, 8	# Load return code.
    addi a7, x0, 93	# Service code to terminate.
    ecall

# Display invalid request, then halt.
invalid_num_words:
    la a0, invalid_num_words_str
    jal strlen		# String len to a2.
    addi a0, x0, 1	# StdOut
    la a1, invalid_num_words_str	# Load addr of prefix string.
    addi a7, x0, 64	# Linux write.
    ecall

    addi a0, x0, 9	# Load return code.
    addi a7, x0, 93	# Service code to terminate.
    ecall

# Get an address of an array item from the stack.
# In:  a0 - stack_array ptr.
# Ret: a1 - item pointer.
stack_array_alloc:
    # Configure stack.
    addi sp, sp, w1n	# Advance sp for stack frame.
    sw ra, 0(sp)	# Save ra.

    # Load stack_address.
    lw a0, sa_stack_ptr(a0)

    # Get item from stack.  Stack may be empty, causing a halt.
    jal stack_pop

    # Cleanup stack.
    lw ra, 0(sp)	# Restore ra.
    addi sp, sp, w1	# Restore sp.

    ret

# Return an address of an array item to the stack.
# In:  a0 - stack_array ptr.
#      a1 - addr to deallocate.
#      Item will be zeroed out.
# Ret: Nothinig.
stack_array_dealloc:
    # Configure stack.
    addi sp, sp, w3n	# Advance sp for stack frame.
    sw ra, 0(sp)	# Save ra.
    sw s1, w1(sp)	# Save s1.
    sw s2, w2(sp)	# Save s2.

    mv s1, a0		# sa struct adr to s1.
    mv s2, a1		# sa item adr to s2.

    # Check address is not already in the stack.
    # This section can be commented out for greater speed.
    lw a0, sa_stack_ptr(s1)
    mv a1, s2
    jal stack_contains
    li t0, 1
    beq a1, t0, sad_err

    # Zero out item memory.
    # This section can be commented out for greater speed.
    lw t0, sa_item_words(s1)	# Load words in item.
    mv t2, s2			# Item ptr to t2.
sad_top_loop:
    beqz t0, sad_end_loop

    sw x0, 0(t2)		# Zero out a word

    addi t0, t0, -1		# Decrement the item word counter.
    addi t2, t2, w1		# Increment the item word pointer.

    j sad_top_loop
sad_end_loop:

    # Return item to stack.
    lw a0, sa_stack_ptr(s1)
    mv a1, s2
    jal stack_push

    # Cleanup stack.
    lw ra, 0(sp)	# Restore ra.
    lw s1, w1(sp)	# Restore s1.
    lw s2, w2(sp)	# Restore s1.
    addi sp, sp, w3	# Restore sp.

    ret

sad_err:
    mv s1, a0		# Save stack ptr.

    jal stack_print_name

    la a0, sca_err_str
    jal strlen			# Get string len into a2.
    addi a0, x0, 1		# StdOut
    la a1, sca_err_str		# Load string addr for call.
    addi a7, x0, 64		# Linux write.
    ecall

    addi a0, x0, 8	# Load return code
    addi a7, x0, 93	# Service code 93 terminates program.
    ecall

invalid_num_words_str:     .asciz "stack_array_new: Invalid number of words"
invalid_num_items_str:     .asciz "stack_array_new: Invalid number of items"
sca_err_str:	.asciz " Item already in stack\n"
in_sa_print:	.asciz "\nIn sa print\n"
stk_adr_str:	.asciz "\nStack addr: "
ary_adr_str:	.asciz "Array addr: "
sa_adr_str:	.asciz "\nStack_Array addr: "
