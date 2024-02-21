# Implement a memory store.
#
# The amount of free memory can be set at the mem: label.
#
# Memory can be allocated until the limit is reached.
#
# Memory allocated is initialized to zero.
#
# Memory cannot be deallocated.
.text

# Word sizes. Change if a word is not 32 bits, 4 bytes.
	.equ w1, 8

	# Shift number bits to convert between words and bytes.
	# Change if a word is not 32 bits, 4 bytes.
	.equ sbts, 3

# GLobal labels:
	.global mem_init
	.global mem_alloc
	.global mem_left

# External labels.
	.extern nu2d

# Word sizes. # Change if a word is not 32 bits, 4 bytes.
	.equ w1, 8

        .equ w1n, -8
        
# Initialize the memory store.
# Call from main before using mem_alloc.
# In:  Nothing.
# Out: Nothing.
mem_init:
    la t0, mem		# Load ptr to memory block.
    la t1, mem_ptr	# Load ptr to word storing the ptr to the next free word.
    sw t0, 0(t1)	# Store ptr to memory block.
    ret

# Allocate a block of memory.
# In:  a0 = number words needed.
# Out: a1 = Address of memory block, or
#      Invalid request error.
#      Out of memory error.
mem_alloc:
    blez a0, invalid_request	# Check for zero, or negative, memory request.

    la t0, mem_ptr
    lw a1, 0(t0)	# Get free block pointer, for return.

    slli t1, a0, sbts	# Multiply word number by number bytes per word.
    add t1, a1, t1	# Increment memory pointer to new free block start.

    la t2, end		# Check if new free block pointer is beyond the end of memory.
    bltu t2, t1, out_of_memory

    sw t1, 0(t0)	# Store new free block pointer.

    ret			# Return a1
   
# Display invalid memory request, then halt.
invalid_request:
    addi a0, x0, 1		# StdOut
    la a1, invalid_str		# Load addr of string
    addi a2, x0, 34		# String length
    addi a7, x0, 64		# linux write call
    ecall
 
    addi	a0, x0, 1	# Load return code
    addi	a7, x0, 93	# Service code 93 terminates
    ecall			# Call linux to terminate the program

invalid_str:	 .ascii "mem_alloc: Invalid memory request\n"

# Display out of memory error, then halt.
out_of_memory:
    la a1, out_str		# Load addr of string
    addi a2, x0, 14		# String length
    addi a7, x0, 64		# linux write call
    ecall
    
    addi	a0, x0, 2	# Load return code
    addi	a7, x0, 93	# Service code 93 terminates
    ecall			# Call linux to terminate the program

out_str:	 .ascii "Out of memory\n"

# Print the amount of memory that is left.
# In:  Nothing.
# Out: A message is displayed.
mem_left:
    # Configure stack.
    addi sp, sp, w1n		# Advance sp for stack frame.
    sw ra, 0(sp)                # Save ra.
    
    # Get pointer to next free block.
    la t0, mem_ptr
    lw t1, 0(t0)

    la t2, end	# Get end of memory

    sub t3, t2, t1	# Get difference, in bytes.
    srli t3, t3, sbts	# Convert to words.
    
    mv a0, t3		# Load number to print
    jal nu2d
    
    addi a0, x0, 1		# StdOut
    la a1, mem_left_str1	# Load addr of string
    addi a2, x0, 10		# String length
    addi a7, x0, 64		# linux write call
    ecall

    la t0, mem_ptr	# Get ptr to memory start.
    la t2, end		# Get ptr to memory end.
    sub t3, t2, t0	# Get difference, in bytes.
    srli t3, t3, sbts	# Convert to words.
    
    mv a0, t3		# Load number to print.
    jal nu2d		# Print it in base 10.
    
    addi a0, x0, 1		# StdOut
    la a1, mem_left_str2	# Load addr of string
    addi a2, x0, 28		# String length
    addi a7, x0, 64		# linux write call
    ecall
    
    # Restore stack.
    lw ra, 0(sp)		# Restore ra.
    addi sp, sp, w1             # Restore sp.

    ret

mem_left_str1: .ascii	" Words of "
mem_left_str2: .ascii	" allocate-only memory left.\n"

cr: .asciz "\n"

.data

# Pointer to the next free memory block.
.align w1
mem_ptr:	 .word 0

# Start, and end of free memory allocation.
mem:		.zero 4000 	# Number bytes, but .zero fills to a whole number of words. Should be divisible by 8.
end:

