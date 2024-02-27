# Implement a memory store.
#
# Memory can be allocated until the limit is reached.
#
# Memory allocated is initialized to zero.
#
# Memory cannot be deallocated.
.text

# Set available memory.
	.equ number_bytes, 4000

# Doubleword sizes:
	.equ d1, 8
	
	.equ d1n, -8

# Shift number bits to convert between words and bytes.
	.equ wbyts, 2

# Global labels:
	.global mem_init
	.global mem_alloc
	.global mem_left

# External labels:
	.extern endprg		# End program.
	.extern prtdec		# Print a number in base 10.
        
# Initialize the memory store.
# Call from main before using mem_alloc.
# In:  Nothing.
# Out: Nothing.
mem_init:
    la t0, mem		# Load ptr to memory block.
    la t1, mem_ptr	# Load ptr to word storing the ptr to the next free word.
    sd t0, 0(t1)	# Store ptr to memory block.
    ret

# Allocate a block of memory.
# In:  a0 = number words needed.
# Ret: a1 = Address of memory block.
mem_alloc:
    blez a0, invalid_request	# Check for zero, or negative, memory request.

    la t0, mem_ptr
    ld a1, 0(t0)	# Get free block pointer, for return.

    slli t1, a0, wbyts	# Multiply word number by number bytes per word.
    add t1, a1, t1	# Increment memory pointer to new free block start.

    la t2, mem_end	# Check if new free block pointer is beyond the end of memory.
    bltu t2, t1, out_of_memory

    sd t1, 0(t0)	# Store new free block pointer.

    ret			# Return a1
   
# Display invalid memory request, then halt.
invalid_request:

    la a0, invalid_str	# Load addr of string.
    jal prtstr
    
    addi a0, x0, 1	# Load return code
    jal endprg
    
# Display out of memory error, then halt.
out_of_memory:
    la a0, out_str	# Load addr of string.
    jal prtstr
    
    add	a0, x0, 2	# Load return code
    jal endprg

# Print the amount of memory that is left, to StdOut.
# In:  Nothing.
# Out: A message is displayed.
mem_left:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    
    # Get pointer to next free block.
    la t0, mem_ptr
    ld t1, 0(t0)

    la t2, mem_end	# Get end of memory

    sub t3, t2, t1	# Get difference, in bytes.
    srli t3, t3, wbyts	# Convert to words.
    
    mv a0, t3		# Load number to print
    jal prtdec
 
    la a0, mem_left_str1	# Load addr of string.
    jal prtstr
    
    la t0, mem		# Get ptr to memory start.
    la t2, mem_end	# Get ptr to memory end.
    sub t3, t2, t0	# Get difference, in bytes.
    srli t3, t3, wbyts	# Convert to words.
    
    mv a0, t3		# Load number to print.
    jal prtdec		# Print it in base 10.
  
    la a0, mem_left_str2	# Load addr of string.
    jal prtstr
    
    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

invalid_str:	.asciz "Invalid memory request\n"
out_str:	.asciz "Out of memory\n"
mem_left_str1:	.asciz	" Words of "
mem_left_str2:	.asciz	" allocate-only memory left.\n"

.data

# Pointer to the next free memory block.
.align d1
mem_ptr:	 .dword 0

# Start, and end of free memory allocation.
mem:		.zero number_bytes
mem_end:

