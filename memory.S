# Implement a memory store.
#
# Memory can be allocated until the limit is reached.
#
# Memory allocated is initialized to zero.
#
# Memory cannot be deallocated.
.text

# Set available memory.
	.equ number_bytes, 8000

# Doubleword sizes:
	.equ d1,  8
	.equ d2, 16 
	
	.equ d1n,  -8
	.equ d2n, -16

# Shift number bits to convert between words and bytes.
	.equ wbyts, 2

# Global labels:
	.global mem_init
	.global mem_alloc
	.global mem_left
	.global mem_within

# Initialize the memory store.
# Call from main before using mem_alloc.
# In:  Nothing.
# Out: Nothing.
# SE:  Local memory initialized.
###########################################
mem_init:
    # Configure stack.
    addi sp, sp, d1n	# Advance sp for stack frame.
    sd ra, 0(sp)	# Save ra.

    la t1, mem_ptr_addr	# Load addr of word storing the ptr to the next free word.
    ld t1, 0(t1)

    ld t0, 0(t1)	# Check for previous inititalization.
    bnez t0, mem_init_err

    la t0, mem_start_addr	# Load ptr to memory block.
    ld t0, 0(t0)

    sd t0, 0(t1)	# Store ptr to memory block.
    j mem_init_ret

mem_init_err:
    la a0, mem_init_err_str
    jal prtstr

mem_init_ret:
    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    addi sp, sp, d1	# Restore sp.

    ret

mem_init_err_str: .asciz "mem_init: Memory already initialized\n"
.align 4

# Allocate a block of memory.
# In:  a0 = number words needed.
# Ret: a1 = Address of memory block.
# SE:  mem_ptr changed to a higher value.
##########################################
mem_alloc:
    blez a0, invalid_request	# Check for zero, or negative, memory request.

    la t0, mem_ptr_addr	# Load addr of word storing the ptr to the next free word.
    ld t0, 0(t0)

    ld a1, 0(t0)	# Get free block pointer, for return.
    beqz a1, mem_not_inititalized

    slli t1, a0, wbyts	# Multiply word number by number bytes per word.
    add t1, a1, t1	# Increment memory pointer to new free block start.

    la t2, mem_end_addr	# Check if new free block pointer is beyond the end of memory.
    ld t2, 0(t2)

    bltu t2, t1, out_of_memory

    sd t1, 0(t0)	# Store new free block pointer.

    ret			# Return a1
   
# Display invalid memory request, then halt.
invalid_request:

    la a0, invalid_str	# Load addr of string.
    jal prtstr
    
    li a0, 1	# Load return code
    j endprg
    
# Display out of memory error, then halt.
out_of_memory:
    la a0, out_str	# Load addr of string.
    jal prtstr
    
    li	a0, 2	# Load return code
    j endprg

out_str:	.asciz "mem_alloc: Out of memory\n"
invalid_str:	.asciz "mem_alloc: Invalid memory request\n"
.align 4

# Print the amount of memory that is left, to StdOut.
# In:  Nothing.
# Ret: Nothing.
# SE:  Text to StdOut.
######################################################
mem_left:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    
    # Print prefix.
    la a0, mem_left_str1
    jal prtstr

    # Get pointer to next free block.
    la t0, mem_ptr_addr	# Load addr of word storing the ptr to the next free word.
    ld t0, 0(t0)

    ld t1, 0(t0)
    beqz t1, mem_not_inititalized

    la t2, mem_end_addr	# Check if new free block pointer is beyond the end of memory.
    ld t2, 0(t2)

    sub t3, t2, t1	# Get difference, in bytes.
    srli t3, t3, wbyts	# Convert to words.
    
    mv a0, t3		# Load number to print
    jal prtdec
 
    la a0, mem_left_str2	# Load addr of string.
    jal prtstr
    
    la t0, mem_start_addr	# Load ptr to memory block.
    ld t0, 0(t0)

    la t2, mem_end_addr	# Check if new free block pointer is beyond the end of memory.
    ld t2, 0(t2)

    sub t3, t2, t0	# Get difference, in bytes.
    srli t3, t3, wbyts	# Convert to words.
    
    mv a0, t3		# Load number to print.
    jal prtdec		# Print it in base 10.
  
    la a0, mem_left_str3	# Load addr of string.
    jal prtstr
    
    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

mem_left_str1:	.asciz	"Allocate-only memory: "
mem_left_str2:	.asciz	" Words of "
mem_left_str3:	.asciz	" left.\n"
.align 4

# Print inititalization error and exit.
mem_not_inititalized:
    la a0, mni_str
    jal prtstr

    li a0, 3
    j endprg

mni_str: 	.asciz "Memory not initialized\n"
.align 4

# Return true if a given address is within memory.
# In:  a0 - Address.
# Ret: a0 - 1 = true, 0 = false.
# SE:  Nothing.
###################################################
mem_within:
    la t0, mem_start_addr
    ld t0, 0(t0)

    blt a0, t0, wm_ret_false

    la t0, mem_end_addr
    ld t0, 0(t0)

    bgt a0, t0, wm_ret_false	

    li a0, 1
    ret

wm_ret_false:
    li a0, 0
    ret

mem_ptr_addr:	.dword mem_ptr
mem_start_addr:	.dword mem_start
mem_end_addr:	.dword mem_end

.data

# Pointer to the next free memory block.
mem_ptr:	 .dword 0

# Start, and end of free memory allocation.
mem_start:		.zero number_bytes
mem_end:		.zero 1

