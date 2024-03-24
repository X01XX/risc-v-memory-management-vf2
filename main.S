
.text

.include "macros.S"

# Global labels:
	.global _start

	.global stack_new
	.global stack_push
	.global stack_pop
	.global stack_print
	.global stack_contains

# Doubleword sizes.
	.equ d1, 8

	.equ d1n, -8

_start:
    # Init alloc-only memory bank.
    excall t0, mem_init

    # Init links struct alloc/dealloc stack-array memory.
    li a0, 3		# Load maximum number of items in use at any one time. 
    excall t0, link_init

    # Init element struct alloc/dealloc stack-array memory.
    li a0, 3		# Load maximum number of items in use at any one time.
    excall t0, element_init
 
after_init:
    excall t0, link_stack_print

    excall t0, element_stack_print

    excall t0, prtnl

    # Init new list, save to s1.
    excall t0, list_new
    mv s1, a0

    # Make a new element instance.
    la a0, he_name
    li a1, 2
    excall t0, element_new	# New element instance to a0.
    mv s2, a0

    # Push to list.
    mv a0, s1		# Load list ptr.
    mv a1, s2
    excall t0, list_push

    # Make a new element instance.
    la a0, h_name
    li a1, 1
    excall t0, element_new	# New element instance to a0.
    mv s2, a0		# Save ptr.

    # Push to list.
    mv a0, s1		# Load list ptr.
    mv a1, s2
    excall t0, list_push

    # Print list.
    la a0, list_str
    excall t0, prtstr

    mv a0, s1		# Load list ptr.
    la a1, sep1
    excall t0, element_list_print
    excall t0, prtnl

    # Print memory summary, so far.
    jal mem_summary

    # Display length and empty
    la a0, len_str
    excall t0, prtstr

    mv a0, s1
    excall t0, list_len

    excall t0, prtdec
    #
    la a0, empty_str
    excall t0, prtstr

    mv a0, s1
    excall t0, list_is_empty
    excall t0, prtdec

    excall t0, prtnl

    excall t0, link_stack_print
    excall t0, element_stack_print

    # Pop, save, a value.
    mv a0, s1
    excall t0, list_pop
    mv s3, a0

    # Print popped value.
    excall t0, prtnl
    la a0, popped_str
    excall t0, prtstr

    mv a0, s3
    excall t0, element_print
    excall t0, prtnl

    # Dealloc popped value.
    mv a0, s3
    excall t0, element_dealloc

    # Print list after pop.
    excall t0, prtnl
    la a0, leaving_str
    excall t0, prtstr

    mv a0, s1		# Load list ptr.
    la a1, sep1
    excall t0, element_list_print

    excall t0, prtnl

    # Display length and empty
    excall t0, prtnl
    la a0, len_str
    excall t0, prtstr

    mv a0, s1
    excall t0, list_len
    excall t0, prtdec
    #
    la a0, empty_str
    excall t0, prtstr

    mv a0, s1
    excall t0, list_is_empty
    excall t0, prtdec

    excall t0, prtnl

    # Pop, save, a value.
    mv a0, s1
    excall t0, list_pop
    mv s3, a0

    # Print popped value.
    excall t0, prtnl
    la a0, popped_str
    excall t0, prtstr

    mv a0, s3
    excall t0, element_print
    excall t0, prtnl

    # Dealloc popped value.
    mv a0, s3
    excall t0, element_dealloc

    # Print list after pop.
    excall t0, prtnl
    la a0, leaving_str
    excall t0, prtstr

    mv a0, s1		# Load list ptr.
    la a1, sep1
    excall t0, element_list_print
    excall t0, prtnl

    # Display length and empty
    excall t0, prtnl
 
    la a0, len_str
    excall t0, prtstr
    mv a0, s1
    excall t0, list_len
    excall t0, prtdec
    #
    la a0, empty_str
    excall t0, prtstr

    mv a0, s1
    excall t0, list_is_empty
    excall t0, prtdec

    # Dealloc empty list
    mv a0, s1
    excall t0, element_list_dealloc

    excall t0, prtnl

    excall t0, link_stack_print

    excall t0, element_stack_print

    jal mem_summary

    mv a0, x0
    excall t0, endprg

# Print a summary of memory usage.
# In:  Nothing.
# Ret: Nothing.
# Out: Text to StdOut.
mem_summary:

    # Configure stack.
    addi sp, sp, d1n	# Advance sp for stack frame.
    sd ra, 0(sp)	# Save ra.

    excall t0, prtnl
    excall t0, mem_left
    excall t0, link_left
    excall t0, element_left
    # Any number of additional pstruct stack_arrays.

    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    addi sp, sp, d1	# Restore sp.

    ret

#### Immutable Data ####

sep1: .asciz ", "
h_name: .asciz "Hydrogen"
he_name: .asciz "Helium"
popped_str: .asciz "popped: "
leaving_str: .asciz "leaving "
list_str: .asciz "List: "
len_str: .asciz "Len: "
empty_str: .asciz " Empty: "

# External function addresses.
##############################
prtstr_addr:			.dword prtstr
prtdec_addr:			.dword prtdec
prtnl_addr:			.dword prtnl
endprg_addr:			.dword endprg
mem_init_addr:			.dword mem_init
mem_left_addr:			.dword mem_left
list_new_addr:			.dword list_new
list_len_addr:			.dword list_len
list_pop_addr:			.dword list_pop
list_push_addr:			.dword list_push
list_is_empty_addr:		.dword list_is_empty
link_init_addr:			.dword link_init
link_left_addr:			.dword link_left
link_stack_print_addr:		.dword link_stack_print
element_init_addr:		.dword element_init
element_new_addr:		.dword element_new
element_left_addr:		.dword element_left
element_print_addr:		.dword element_print
element_dealloc_addr:		.dword element_dealloc
element_stack_print_addr:	.dword element_stack_print
element_list_print_addr:	.dword element_list_print
element_list_dealloc_addr:	.dword element_list_dealloc





