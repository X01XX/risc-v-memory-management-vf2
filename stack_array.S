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

.text

.include "macros.S"

# Comment out this, to make deallocation faster, but allow inadvertant use of deallocated data.
	.equ zero_memory, 1

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
	.equ 	sa_array_ptr,  12	# 8 bytes, 2 words. Ptr to array memory.
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

    # Check number items.
    beqz s1, stack_array_new_num_items_err
    li t0, 0xFFFF
    bgt s1, t0, stack_array_new_num_items_err

    # Check number words per item.
    beqz s2, stack_array_new_num_words_err
    li t0, 0xFFFF
    bgt s2, t0, stack_array_new_num_words_err

    # Allocate sa struct.
    li	a0, sa_words		# Load number words in SA struct.
    excall t0, mem_alloc	# Get ptr to array into a0.
    mv s7, a0			# Save sa struct ptr.

    # Set struct ID.
    li t0, stack_array_id_val
    sw t0, sa_id(s7)

    # Add number items to struct.
    sh s1, sa_num_items(s7)

    # Add words per item, to struct.
    sh s2, sa_item_words(s7)

    # Allocate new stack.
    mv	a0, s1			# Load number of items.
    mv	a1, s3			# Load ptr to description.
    excall t0, stack_new	# Get ptr to stack in a0.

    # Save stack struct ptr to SA struct.
    sd  a0, sa_stack_ptr(s7)
	
    # Allocate array.

    # Calc array words.
    mul a0, s1, s2		# Get number of words of array memory needed.
    excall t0, mem_alloc	# a0 contains number words needed.  Get memory allocation for array into a0.

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
    excall t0, stack_push
    
    add s5, s5, s6	# Point to next array item.

    addi s1, s1, -1	# Decrement number items.

    bgtz s1, loop	# Continue if more items to fill.
    
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

stack_array_new_num_items_err:
    la a0, stack_array_new_num_items_err_str
    excall t0, prtstr

    li a0, 15	# Load return code.
    excall t0, endprg

stack_array_new_num_words_err:
    la a0, stack_array_new_num_words_err_str
    excall t0, prtstr

    li a0, 16	# Load return code.
    excall t0, endprg


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

    # Check its in local memory.
    mv a0, s1
    excall t0, mem_within	# Avoid a segmentation error in next lwu command.
    beqz a0, is_stack_array_ret_0

    # Check struct ID.
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

    mv a0, s1
    jal is_stack_array
    beqz a0, stack_array_print_arg_err

    # Print stack_array address prefix.
    la a0, sa_adr_str	# Load addr of prefix string.
    excall t0, prtstr

    # Print stack_array address.
    mv a0, s1
    excall t0, prthex		# Print addr.

    # Print stack address prefix.
    la a0, stk_adr_str
    excall t0, prtstr

    # Print stack address.
    ld a0, sa_stack_ptr(s1)
    excall t0, prthex
    excall t0, prtnl

    # Print stack.
    ld a0, sa_stack_ptr(s1)
    excall t0, stack_print
    
    # Print array address prefix.
    la a0, ary_adr_str
    excall t0, prtstr

    # Print array address.
    ld a0, sa_array_ptr(s1)
    excall t0, prthex

    excall t0, prtnl

    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    ld s1, d1(sp)	# Restore s1.
    addi sp, sp, d2	# Restare sp.

    ret

stack_array_print_arg_err:
    la a0, stack_array_print_arg_err_str
    excall t0, prtstr

    li a0, 17
    excall t0, endprg


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

    mv a0, s1
    jal is_stack_array
    beqz a0, stack_array_alloc_arg_err

    # Load stack_address.
    ld a0, sa_stack_ptr(s1)

    # Get item from stack, into a0.
    excall t0, stack_pop

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

stack_array_alloc_arg_err:
    la a0, stack_array_alloc_arg_err_str
    excall t0, prtstr

    li a0, 18
    excall t0, endprg


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

    # Check arg 1.
    mv a0, s1
    jal is_stack_array
    beqz a0, stack_array_dealloc_arg_err

    # Check arg 2 for non-struct.
    mv a0, s2
    excall t0, mem_within
    beqz a0, stack_array_dealloc_arg_err2

    # Check arg 2 for double deallocation.
    lw t0, 0(s2)
    beqz t0, stack_array_dealloc_arg_err3
 
.ifdef zero_memory
    # Zero out item memory.
    lhu t0, sa_item_words(s1)	# Load words in item.
    mv t2, s2			# Item ptr to t2.
sad_loop:
    sw x0, 0(t2)		# Zero out a word

    addi t2, t2, 4		# Increment the item word pointer.
    addi t0, t0, -1		# Decrement the item word counter.

    bnez t0, sad_loop
.else
    # zero out the struct ID.
    sw x0, 0(s2)
.endif

    # Return item to stack.
    ld a0, sa_stack_ptr(s1)
    mv a1, s2
    excall t0, stack_push

    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    ld s1, d1(sp)	# Restore s1.
    ld s2, d2(sp)	# Restore s1.
    addi sp, sp, d3	# Restore sp.

    ret

sad_err:
    mv a0, s1
    excall t0, stack_print_name

    la a0, sca_err_str
    excall t0, prtstr

    li a0, 20	# Load return code
    excall t0, endprg

stack_array_dealloc_arg_err:
    la a0, stack_array_dealloc_arg_err_str
    excall t0, prtstr

    li a0, 19
    excall t0, endprg

stack_array_dealloc_arg_err2:
    la a0, stack_array_dealloc_arg_err_str2
    excall t0, prtstr

    li a0, 19
    excall t0, endprg

stack_array_dealloc_arg_err3:
    la a0, stack_array_dealloc_arg_err_str3
    excall t0, prtstr

    li a0, 19
    excall t0, endprg

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

    mv a0, s1
    jal is_stack_array
    beqz a0, stack_array_left_arg_err

    ld a0, sa_stack_ptr(s1)	# Get stack addr.
    excall t0, stack_left

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

stack_array_left_arg_err:
    la a0, stack_array_left_arg_err_str
    excall t0, prtstr

    li a0, 21
    excall t0, endprg

#### Immutable Data ####

# External function addresses.
##############################
prtstr_addr:		.dword prtstr
prtdec_addr:		.dword prtdec
prthex_addr:		.dword prthex
prtchr_addr:		.dword prtchr
prtnl_addr:		.dword prtnl
endprg_addr:		.dword endprg
mem_alloc_addr:		.dword mem_alloc
mem_within_addr:	.dword mem_within
stack_push_addr:	.dword stack_push
stack_pop_addr:		.dword stack_pop
stack_left_addr:	.dword stack_left
stack_print_name_addr:	.dword stack_print_name
stack_contains_addr:	.dword stack_contains
stack_print_addr:	.dword stack_print
stack_new_addr:		.dword stack_new

# stack_array_new:
stack_array_new_num_words_err_str:	.asciz "stack_array_new: Invalid number of words per item.\n"
stack_array_new_num_items_err_str:	.asciz "stack_array_new: Invalid number of items.\n"

# stack_array_print:
stk_adr_str:	.asciz "\nStack addr: "
ary_adr_str:	.asciz "Array addr: "
sa_adr_str:	.asciz "\nStack_Array addr: "
stack_array_print_arg_err_str:	.asciz	"stack_array_print: Arg passed is not a stack array.\n"

# stack_array_alloc:
stack_array_alloc_arg_err_str:	.asciz	"stack_array_alloc: Arg passed is not a stack array.\n"

# stack_array_dealloc:
sca_err_str:	.asciz "stack_array_dealloc: Item already in stack\n"
stack_array_dealloc_arg_err_str:	.asciz	"stack_array_dealloc: Arg passed is not a stack_array.\n"
stack_array_dealloc_arg_err_str2:	.asciz	"stack_array_dealloc: Arg passed is not a struct.\n"
stack_array_dealloc_arg_err_str3:	.asciz	"stack_array_dealloc: Arg passed may already be deallocated.\n"

# stack_array_left:
stack_array_left_arg_err_str:	.asciz	"stack_array_left: Arg passed is not a stack array.\n"

