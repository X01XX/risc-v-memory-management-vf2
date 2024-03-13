
.text

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
    jal mem_init

    # Init links struct alloc/dealloc stack-array memory.
    li a0, 3		# Load maximum number of items in use at any one time. 
    jal link_init

    # Init element struct alloc/dealloc stack-array memory.
    li a0, 3		# Load maximum number of items in use at any one time.
    jal element_init
 
after_init:
    jal link_stack_print

    jal element_stack_print

    jal prtnl

    # Init new list, save to s1.
    jal list_new
    mv s1, a1

    # Make a new element instance.
    la a0, he_name
    li a1, 2
    jal element_new	# New element instance to a1.
    mv s2, a1

    # Push to list.
    mv a0, s1		# Load list ptr.
    mv a1, s2
    jal list_push

    # Make a new element instance.
    la a0, h_name
    li a1, 1
    jal element_new	# New element instance to a1.
    mv s2, a1		# Save ptr.

    # Push to list.
    mv a0, s1		# Load list ptr.
    mv a1, s2
    jal list_push

    # Print list.
    la a0, list_str
    jal prtstr

    mv a0, s1		# Load list ptr.
    la a1, sep1
    jal element_list_print

    # Print memory summary, so far.
    jal prtnl
    jal mem_summary

    # Display length and empty
    la a0, len_str
    jal prtstr

    mv a0, s1
    jal list_len
    mv a0, a1
    jal prtdec
    #
    la a0, empty_str
    jal prtstr

    mv a0, s1
    jal list_is_empty
    mv a0, a1
    jal prtdec

    jal prtnl

    jal link_stack_print
    jal element_stack_print

    # Pop, save, a value.
    mv a0, s1
    jal list_pop
    mv s3, a1

    # Print popped value.
    la a0, popped_str
    jal prtstr

    mv a0, s3
    jal element_print

    # Dealloc popped value.
    mv a0, s3
    jal element_dealloc

    # Print list after pop.
    la a0, leaving_str
    jal prtstr

    mv a0, s1		# Load list ptr.
    la a1, sep1
    jal element_list_print

    jal prtnl

    # Display length and empty
    la a0, len_str
    jal prtstr

    mv a0, s1
    jal list_len
    mv a0, a1
    jal prtdec
    #
    la a0, empty_str
    jal prtstr

    mv a0, s1
    jal list_is_empty
    mv a0, a1
    jal prtdec

    jal prtnl

    # Pop, save, a value.
    mv a0, s1
    jal list_pop
    mv s3, a1

    # Print popped value.
    la a0, popped_str
    jal prtstr

    mv a0, s3
    jal element_print

    # Dealloc popped value.
    mv a0, s3
    jal element_dealloc

    # Print list after pop.
    la a0, leaving_str
    jal prtstr

    mv a0, s1		# Load list ptr.
    la a1, sep1
    jal element_list_print

    # Display length and empty
    jal prtnl
 
    la a0, len_str
    jal prtstr
    mv a0, s1
    jal list_len
    mv a0, a1
    jal prtdec
    #
    la a0, empty_str
    jal prtstr

    mv a0, s1
    jal list_is_empty
    mv a0, a1
    jal prtdec

    # Dealloc empty list
    mv a0, s1
    jal element_list_dealloc

    jal prtnl

    jal link_stack_print

    jal element_stack_print

    jal mem_summary

    mv a0, x0
    j endprg

# Print a summary of memory usage.
# In:  Nothing.
# Ret: Nothing.
# Out: Text to StdOut.
mem_summary:

    # Configure stack.
    addi sp, sp, d1n	# Advance sp for stack frame.
    sd ra, 0(sp)	# Save ra.

    jal prtnl
    jal mem_left
    jal link_left
    jal element_left
    # Any number of additional pstruct stack_arrays.

    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    addi sp, sp, d1	# Restore sp.

    ret

sep1: .asciz ", "
h_name: .asciz "Hydrogen"
he_name: .asciz "Helium"
popped_str: .asciz "\npopped: "
leaving_str: .asciz "\n\nleaving "
list_str: .asciz "\nList: "
len_str: .asciz "\nLen: "
empty_str: .asciz " Empty: "
