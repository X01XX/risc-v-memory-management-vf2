# Implement a stack-array and methods.
#
# Run stack_array_new to allocate, and initialize, memory for a new stack_array.
#
# Run stack_array_alloc, to get an address to an available array item.
#
# Run stack_array_dealloc, to return an address that is no longer used.
#
#    There are two sections of code in stack_array_dealloc that can be skipped,
#    for greater speed, but lower detection of errors.  See first equs.
#
#    It does not check for invalid addresses, being deallocated, but that can be done by the caller.
#
# See stack_array struct, below.

# Comment out these, to make deallocation faster, but harder to notice and track down logical errors.
	.equ zero_memory, 1
	.equ check_for_dups, 1

# Doubleword sizes:
	.equ d1, 8
	.equ d2, 16
	.equ d3, 24
	.equ d4, 32
	.equ d5, 40
	.equ d6, 48
	.equ d7, 56
	.equ d8, 64

	.equ d1n, -8
	.equ d2n, -16
	.equ d3n, -24
	.equ d8n, -64

	# Shift number bits to convert between words and bytes.
	.equ wbyts, 2

# Struct stack_array (sa):
	.equ	sa_id,		0	# 4 bytes, 1 word.
	.equ	sa_stack_ptr,   4	# 8 bytes, 2 words. Ptr to stack struct.
	.equ 	sa_array_ptr,  12	# 8 bytes, 2 words. Ptr to array.
	.equ	sa_num_items,  20	# 2 bytes, 1/2 word. Max number items.
	.equ	sa_item_words, 22	# 2 bytes, 1/2 word. Number words per item.
	.equ	sa_words, 6		# Number words in this struct.

# ID to identify a stack_array instance.
	.equ	stack_array_id_val, 1553

# Global labels:
	.global stack_array_new
	.global stack_array_dealloc
	.global stack_array_alloc
	.global stack_array_print
	.global stack_array_left

# Generate a stack-array
# mem_init needs to be called from main before calling this.
#
# In:  a0 - Number of items.
#      a1 - Number of words in each item.
#      a2 - Pointer to string description.
# Ret: a0 - Stack-array instance pointer.
#      The stack is loaded with the ptr to each array item.
#      The array ptr is not needed by the caller, it is only used in this function.
# SE:  Local memory available decreases.
###################################################################################
stack_array_new:
    blez a0, invalid_num_items # Check for zero, or negative, number of items.
    blez a1, invalid_num_words # Check for zero, or negative, number of words.

    # Configure stack.
    addi sp, sp, d8n	# Advance sp for stack frame.
    sd ra, 0(sp)	# Save return addr.
    sd s1, d1(sp)	# Save s1.
    sd s2, d2(sp)	# Save s2.
    sd s3, d3(sp)	# Save s3 
    sd s4, d4(sp)	# Save s4.
    sd s5, d5(sp)	# Save s5.
    sd s6, d6(sp)	# Save s6.
    sd s7, d7(sp)	# Save s7.

    mv s1, a0		# Save number items.
    mv s2, a1		# Save number words per item.
    mv s3, a2		# Save ptr to description.

    # Allocate sa struct.
    li	a0, sa_words	# Load number words in SA struct.
    jal mem_alloc	# Get ptr to array into a0.
    mv s7, a0		# Save sa struct ptr.

    # Set struct ID.
    li t0, stack_array_id_val
    sw t0, sa_id(s7)

    # Add number items to struct.
    sh s1, sa_num_items(s7)

    # Add words per item, to struct.
    sh s2, sa_item_words(s7)

    # Allocate new stack.
    mv	a0, s1		# Load number of items.
    mv	a1, s3		# Load ptr to description.
    jal stack_new	# Get ptr to stack in a0.

    # Save stack struct ptr to SA struct.
    sd  a0, sa_stack_ptr(s7)
	
    # Allocate array.

    # Calc array words.
    mul a0, s1, s2	# Get number of words of array memory needed.
    jal mem_alloc	# a0 contains number words needed.  Get memory allocation for array into a0.

    # Save array ptr to struct.
    sd  a0, sa_array_ptr(s7)
	
    # Push the ptr to each array item onto the stack.

    # Load ptrs to stack and array.
    ld	s4, sa_stack_ptr(s7)	# Load ptr to stack.

    ld	s5, sa_array_ptr(s7)	# Load ptr to array.

    # Calc number bytes per item.
    mv	 s6, s2			# Load number of words in each item.
    slli s6, s6, wbyts		# Multiply number words by word size to get size in bytes.

loop:
    # Push next item ptr to stack.  Need a0, ptr to stack, a1 value to push.
    mv a0, s4		# Load stack ptr for call.
    mv a1, s5		# Load array item ptr for call.
    jal stack_push
    
    add s5, s5, s6	# Point to next array item.

    # Check if done.
    addi s1, s1, -1	# Decrement number items.
    bgtz s1, loop	# Return if zero, no items left.
    
ret:
    mv a0, s7		# Load sa ptr to return.

    # Cleanup stack.
    ld s1, d1(sp)	# Restore s1.
    ld s2, d2(sp)	# Restore s2.
    ld s3, d3(sp)	# Restore s3.
    ld s4, d4(sp)	# Restore s4.
    ld s5, d5(sp)	# Restore s5.
    ld s6, d6(sp)	# Restore s6.
    ld s7, d7(sp)	# Restore s7.
    ld ra, 0(sp)	# Restore ra.
    addi sp, sp, d8	# Restore sp.

    ret			# Return a0

# Display invalid request, then halt.
invalid_num_items:
    la a0, invalid_num_items_str
    jal prtstr

    li a0, 15	# Load return code.
    j endprg

# Display invalid request, then halt.
invalid_num_words:
    la a0, invalid_num_words_str
    jal prtstr

    li a0, 16	# Load return code.
    j endprg

invalid_num_words_str:     .asciz "stack_array_new: Invalid number of words"
invalid_num_items_str:     .asciz "stack_array_new: Invalid number of items"
.align 4

# Check if a ptr references a stack instance.
# In:  a0 - Ptr to instance.
# Ret: a0 - 1 = true, 0 = false.
# SE:  Nothing.
##############################################
is_stack_array:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save addr.

    jal mem_within	# Avoid a segmentation error in next lwu command.
    beqz a0, is_stack_array_ret_0

    lwu t0, sa_id(s1)		# Load instance ID val.
    li t1, stack_array_id_val	# Load expected ID val.

    bne t0, t1, is_stack_array_ret_0

    li a0, 1
    j is_stack_array_ret

is_stack_array_ret_0:
    li a0, 0

is_stack_array_ret:
    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

# Print a stack_array.
# In:  a0 - stack_array ptr.
# Ret: Nothing.
# SE:  Text to StdOut.
###############################
stack_array_print:
    addi sp, sp, d2n	# Advance sp for stack frame.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# sa struct adr to s1.

    jal is_stack_array
    beqz a0, stack_array_print_arg_err

    # Print stack_array address prefix.
    la a0, sa_adr_str	# Load addr of prefix string.
    jal prtstr

    # Print stack_array address.
    mv a0, s1
    jal prthex		# Print addr.

    # Print stack address prefix.
    la a0, stk_adr_str
    jal prtstr

    # Print stack address.
    ld a0, sa_stack_ptr(s1)
    jal prthex

    # Print stack.
    ld a0, sa_stack_ptr(s1)
    jal stack_print
    
    # Print array address prefix.
    la a0, ary_adr_str
    jal prtstr

    # Print array address.
    ld a0, sa_array_ptr(s1)
    jal prthex

    jal prtnl

    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    ld s1, d1(sp)	# Restore s1.
    addi sp, sp, d2	# Restare sp.

    ret

stack_array_print_arg_err:
    la a0, stack_array_print_arg_err_str
    jal prtstr

    li a0, 17
    j endprg

stk_adr_str:	.asciz "\nStack addr: "
ary_adr_str:	.asciz "Array addr: "
sa_adr_str:	.asciz "\nStack_Array addr: "
stack_array_print_arg_err_str:	.asciz	"stack_array_print: Arg passed is not a stack array.\n"
.align 4

# Get an address of an array item from the stack.
# In:  a0 - stack_array instance ptr.
# Ret: a0 - item pointer.
# SE:  stack array changes.
###################################################
stack_array_alloc:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save arg.

    jal is_stack_array
    beqz a0, stack_array_alloc_arg_err

    # Load stack_address.
    ld a0, sa_stack_ptr(s1)

    # Get item from stack, into a0.
    jal stack_pop

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

stack_array_alloc_arg_err:
    la a0, stack_array_alloc_arg_err_str
    jal prtstr

    li a0, 18
    j endprg

stack_array_alloc_arg_err_str:	.asciz	"stack_array_alloc: Arg passed is not a stack array.\n"
.align 4

# Return an address of an array item to the stack.
# In:  a0 - stack_array instance ptr.
#      a1 - addr to deallocate.
#      Item will be zeroed out.
# Ret: Nothing.
# SE:  Stack array changes.
##################################################
stack_array_dealloc:
    # Configure stack.
    addi sp, sp, d3n	# Advance sp for stack frame.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.
    sd s2, d2(sp)	# Save s2.

    mv s1, a0		# sa struct adr to s1.
    mv s2, a1		# sa item adr to s2.

    jal is_stack_array
    beqz a0, stack_array_dealloc_arg_err

.ifdef check_for_dups
    # Check address is not already in the stack.
    # This section can be commented out for greater speed.
    ld a0, sa_stack_ptr(s1)
    mv a1, s2
    jal stack_contains
    li t0, 1
    beq a0, t0, sad_err
.endif

.ifdef zero_memory
    # Zero out item memory.
    # This section can be commented out for greater speed.
    lhu t0, sa_item_words(s1)	# Load words in item.
    mv t2, s2			# Item ptr to t2.
sad_loop:
    sw x0, 0(t2)		# Zero out a word

    addi t2, t2, 4		# Increment the item word pointer.
    addi t0, t0, -1		# Decrement the item word counter.

    bnez t0, sad_loop
.endif

    # Return item to stack.
    ld a0, sa_stack_ptr(s1)
    mv a1, s2
    jal stack_push

    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    ld s1, d1(sp)	# Restore s1.
    ld s2, d2(sp)	# Restore s1.
    addi sp, sp, d3	# Restore sp.

    ret

sad_err:
    mv s1, a0		# Save stack ptr.

    jal stack_print_name

    la a0, sca_err_str
    jal prtstr

    li a0, 20	# Load return code
    j endprg

stack_array_dealloc_arg_err:
    la a0, stack_array_dealloc_arg_err_str
    jal prtstr

    li a0, 19
    j endprg

sca_err_str:	.asciz "stack_array_dealloc: Item already in stack\n"
stack_array_dealloc_arg_err_str:	.asciz	"stack_array_dealloc: Arg passed is not a stack array.\n"
.align 4

# Print a summary of stack_array usage.
# In: a0  - Ptr to a stack_array instance.
# Ret: Nothing.
# SE:  Text to StdOut.
##########################################
stack_array_left:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save arg.

    jal is_stack_array
    beqz a0, stack_array_left_arg_err

    ld a0, sa_stack_ptr(s1)	# Get stack addr.
    jal stack_left

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

stack_array_left_arg_err:
    la a0, stack_array_left_arg_err_str
    jal prtstr

    li a0, 21
    j endprg

stack_array_left_arg_err_str:	.asciz	"stack_array_left: Arg passed is not a stack array.\n"
