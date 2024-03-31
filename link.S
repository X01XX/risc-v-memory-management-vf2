# Implement link struct and methods.
#
# See link struct, below.

.text

.include "macros.S"

# Doubleword sizes:
        .equ d1, 8
        .equ d2, 16
        .equ d3, 24
        .equ d4, 32

        .equ d1n, -8
        .equ d2n, -16
        .equ d3n, -24
        .equ d4n, -32

# Struct link:
        .equ link_id,	 0	# 4 bytes, 1 word. Link pstruct ID number.
        .equ link_next,  4	# 8 bytes, 2 words. Tpr to next link, or zero.
        .equ link_val,  12	# 8 bytes, 2 words. Ptr to value, or zero in empty list.
        .equ link_words, 5

# ID to identify a link instance.
	.equ link_id_val, 1319

#  Global labels:
	.global link_init
	.global link_stack_print
	.global link_print
	.global is_link
	.global link_get_val
	.global link_get_next
	.global link_list_dealloc
	.global list_new
	.global list_push
	.global list_pop
	.global list_len
	.global list_is_empty
	.global link_left
	.global link_new

# Initialize link storage.
# mem_init needs to be called from main before calling this.
#
# In:  a0 contains the number of items to allow for.
# Ret: Nothing.
# SE:  Stack array initilized.
############################################################
link_init:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    # Load link_sa_ptr addr.
    la s1, link_sa_ptr_addr
    ld s1, 0(s1)

    # Check for previous initialization.
    ld t1, 0(s1)
    bnez t1, link_init_err

    # Allocate and configure new SA.
    li a1, link_words   # Load number words per item.
    la a2, link_str     # Load stack_array decription ptr.
    li a3, link_id_val	# Load struct ID.
    excall t0, stack_array_new # sa struct adr to a0

    sd a0, 0(s1)		# Store stack_array address.

    j link_init_ret

# Print error, but continue.
link_init_err:
    la a0, link_init_err_str
    excall t0, prtstr

link_init_ret:
    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

# Return a new link.
# In:  a0 = Link value.
#      a1 = Link next.
# Ret: a0 = Link instance ptr.
# SE:  Stack array changed.
###############################
link_new:
    # Configure stack.
    addi sp, sp, d3n
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)               # Save s1.
    sd s2, d2(sp)               # Save s2.

    # Save args.
    mv s1, a0                   # Save link value to s1.
    mv s2, a1                   # Save link next to s2.

    # Allocate a new link instance.
    la a0, link_sa_ptr_addr	# Load link SA ptr.
    ld a0, 0(a0)
    ld a0, 0(a0)
    beqz a0, link_sa_not_inititalized	# Check SA was previously initialized.
    excall t0, stack_array_alloc	# Get a new link instance ptr, in a0.

    # Store values into instance.
    #li t0, link_id_val		# Set link id.
    #sw t0, link_id(a0)
    sd s1, link_val(a0)		# Store link value ptr.
    sd s2, link_next(a0)	# Store link next ptr.

    # Restore stack.
    ld s2, d2(sp)               # Restore s2.
    ld s1, d1(sp)               # Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

# Return an empty list, a link with value 0, next 0.
# In:  Nothing.
# Ret: a0 = empty list.
# SE:  Stack array changed.
#####################################################
list_new:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.

    # Get new, empty, link instance.
    mv a0, x0
    mv a1, x0
    jal link_new		# New link to a0.

    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

# Pop a value from a list.
# In:  a0 = List (first link) ptr.
# Ret: a0 = First list value ptr.
# SE:  Stack array changed.
# The address of the first link, as
# the start of the list, is preserved.
#######################################
list_pop:
    # Configure stack.
    addi sp, sp, d4n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.
    sd s3, d3(sp)		# Save s3.

    # Save arg.
    mv s1, a0			# Save link ptr.

    # Check arg a0.
    jal is_link
    beqz a0, list_pop_arg_err         # Error if not a link.

    # Check if empty list.
    mv a0, s1
    jal list_is_empty
    bnez a0, list_pop_empty_err

    # Save link value to return.
    ld s2, link_val(s1)

    # Save link next ptr
    ld s3, link_next(s1)

    # Check for last link.
    beq s3, x0, list_pop_last

    # Move value from next link to first link.
    ld t0, link_val(s3)
    sd t0, link_val(s1)

    # Move next ptr from next link to first link.
    ld t0, link_next(s3)
    sd t0, link_next(s1)

    # Dealloc next link.
    mv a0, s3
    jal link_dealloc

    j list_pop_end

list_pop_last:
    sd x0, link_val(s1)		# Change first link to empty list, link_next already 0.
    
list_pop_end:
    # Load value to return.
    mv a0, s2

    # Restore stack.
    ld s3, d3(sp)		# Restore s3.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d4             # Restore sp.

    ret
 
# Print argument error, exit.
list_pop_arg_err:
    la a0, list_pop_arg_err_str
    excall t0, prtstr

    li a0, 22	# Load return code.
    excall t0, endprg

# Print empty list error, exit.
list_pop_empty_err:
    la a0, list_pop_empty_err_str
    excall t0, prtstr

    li a0, 23	# Load return code.
    excall t0, endprg

# Push a value onto a list of structs, sharing the same ID value.
# Preserve the first link, as start of the list, is preserved.
# In:  a0 = a link ptr.
#      a1 = value ptr. a1 = struct value, with ID in first word.
# Ret: Nothing.
# SE:  Stack array changed.
###########################################################################
list_push:
    # Configure stack.
    addi sp, sp, d3n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.

    # Save args.
    mv s1, a0			# Save link ptr.
    mv s2, a1			# Save value ptr.

    # Check that the arg is a linkthat the arg is a link.
    mv a0, s1
    jal is_link
    beqz a0, list_push_arg_err

    # Check for empty list.
    mv a0, s1
    jal list_is_empty
    bnez a0, list_push_empty_list
    
    # List is not empty.

    # Check value ids is equal to other IDs in the list.
    ld t0, link_val(s1)		# Get first link value.
    lwu t0, 0(t0)		# Get value ID.
    lwu t1, 0(s2)		# Get value-to-push ID.
    bne t0, t1, list_push_type_err

    # Get new link, to a0.
    mv a0, x0
    mv a1, x0
    jal link_new

    # Move first link value into the new link.
    ld t0, link_val(s1)
    sd t0, link_val(a0)

    # Move first link next ptr into the new link.
    ld t0, link_next(s1)
    sd t0, link_next(a0)

    sd a0, link_next(s1)	# Make first link next point to new link.

    sd s2, link_val(s1)  	# Make first link value equal new value.

    j list_push_end

list_push_empty_list:
    sd s2, link_val(s1)		# Store value in first link.

list_push_end:
    # Restore stack.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

# Print arg error, exit.
list_push_arg_err:
    la a0, list_push_arg_err_str
    excall t0, prtstr

    li a0, 24
    excall t0, endprg

# Print arg error, exit.
list_push_type_err:
    la a0, list_push_type_err_str
    excall t0, prtstr

    li a0, 25
    excall t0, endprg


# Deallocate a link.
# In: a0 contains a pointer to a link instance.
# Ret: Nothing.
# SE:  Stack array changed.
###############################################
link_dealloc:
   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save arg ptr.

    # Check arg.
    jal is_link
    beqz a0, list_dealloc_arg_err

    la a0, link_sa_ptr_addr	# Load Link SA ptr.
    ld a0, 0(a0)
    ld a0, 0(a0)

    mv a1, s1			# Load Link ptr.

    excall t0, stack_array_dealloc	# Deallocate.

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

# Print error string, exit.
list_dealloc_arg_err:
    la a0, list_dealloc_arg_err_str
    excall t0, prtstr

    li a0, 26
    excall t0, endprg


# Check if a ptr references a link instance.
# In:  a0 - Ptr to instance.
# Ret: a0 - 1 = true, 0 = false.
# SE:  Nothing.
############################################
is_link:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save addr.

    excall t0, mem_within	# Avoid a segmentation error in next lwu command.
    beqz a0, is_link_ret_0

    lwu t0, link_id(s1)	# Load instance ID val.
    li t1, link_id_val	# Load expected ID val.

    bne t0, t1, is_link_ret_0	# Check IDs are equal.

    li a0, 1
    j is_link_ret

is_link_ret_0:
    li a0, 0

is_link_ret:
    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

# Accessor to get link value.
# In:  a0 = ptr to link instance.
# Ret: a0 = link value.
# SE:  Nothing.
##################################
link_get_val:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save arg.

    # Check instance ID.
    jal is_link
    beqz a0, link_get_val_arg_err	# Branch if arg is not a link.

    ld a0, link_val(s1)		# Load link value to return.

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.
    ret

# Print error, exit.
link_get_val_arg_err:
    la a0, link_get_val_arg_err_str
    excall t0, prtstr

    li a0, 27
    excall t0, endprg

# Accessor to get link next.
# In:  a0 = ptr to link instance.
# Ret: a0 = link next.
# SE:  Nothing.
##################################
link_get_next:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save arg.

    # Check instance ID.
    jal is_link
    beqz a0, link_get_next_arg_err	# Branch if not link.

    ld a0, link_next(s1)	# Load link next to return.

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.
    ret

# Print error, exit.
link_get_next_arg_err:
    la a0, link_get_next_arg_err_str
    excall t0, prtstr

    li a0, 28
    excall t0, endprg


# Print the link stack.
# In:  Nothing.
# Ret: Nothing.
# SE:  Prints info to StdOut.
##############################
link_stack_print:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.

    # Load link_sa_ptr.
    la t0, link_sa_ptr_addr
    ld t0, 0(t0)
    ld a0, 0(t0)

    beqz a0, link_sa_not_inititalized	# Error if not yet initialized.

    excall t0, stack_array_print	# Print the stack.
   
    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

# Print an link instance.
# In:  a0 = ptr to a link instance.
# Ret: Nothing.
# SE:  Prints info to StdOut.
###################################
link_print:
    # Configure stack.
    addi sp, sp, d2n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.

    mv s1, a0			# Save link ptr.

    # Check instance ID.
    jal is_link
    beqz a0, link_print_arg_err	# Error if not a link.

    # Print prfix string.
    la a0, link_print_val_str
    excall t0, prtstr

    # Print link value.
    ld a0, link_val(s1)
    excall t0, prthex

    # Print next string.
    la a0, link_print_nxt_str
    excall t0, prtstr

    # Print link next value.
    ld a0, link_next(s1)
    excall t0, prthex

    # Print right bracket.
    li a0, ']'
    excall t0, prtchr

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2             # Restore sp.

    ret

# Print error, exit.
link_print_arg_err:
    la a0, link_print_arg_err_str
    excall t0, prtstr

    li a0, 29
    excall t0, endprg


# Deallocate a linked list.
# Clear values from the list before calling this.
# In:  a0 = ptr to a link instance.
# Ret: Nothing.
# SE:  Stack array changed.
##################################################
link_list_dealloc:
    # Configure stack.
    addi sp, sp, d3n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.

    # Save arg.
    mv s1, a0			# Save link ptr.

    # Check instance is a Link.
    jal is_link
    beqz a0, link_list_dealloc_arg_err

ldl_loop_next:
    mv s2, s1			# Save current link ptr.

    ld s1, link_next(s1)	# Load link next.

    # Dealloc current link.
    mv a0, s2
    jal link_dealloc

    bnez s1, ldl_loop_next	# Branch if another link.

    # Restore stack.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

# Print error, exit.
link_list_dealloc_arg_err:
    la a0, link_list_dealloc_arg_err_str
    excall t0, prtstr

    li a0, 30
    excall t0, endprg


# Return the length of a list.
# In:  a0 = ptr to a link instance.
# Ret: a0 = list length.
# SE:  Nothing.
###################################
list_len:
    # Configure stack.
    addi sp, sp, d2n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.

    mv s1, a0			# Save link ptr.

    # Check that arg is a Link.
    jal is_link
    beqz a0, list_len_arg_err

    # Check for empty list.
    mv a0, s1
    jal list_is_empty
    bnez a0, list_len_empty

    mv a0, x0			# Init counter.

list_len_loop_next:
    addi a0, a0, 1		# Increment counter.

    ld s1, link_next(s1)	# Load link next.

    bnez s1, list_len_loop_next	# Process next link.

    j list_len_end

list_len_empty:
    li a0, 0			# Load length to return.

list_len_end:
    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2             # Restore sp.

    ret

# Print error, exit.
list_len_arg_err:
    la a0, list_len_arg_err_str
    excall t0, prtstr

    li a0, 31
    excall t0, endprg


# Return 1 if a list is empty, otherwise return 0.
# In:  a0 = ptr to a link instance.
# Ret: a0 = 1 or 0.
# SE:  Nothing.
###################################################
list_is_empty:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save arg.

    # Check instance ID.
    jal is_link
    beqz a0, list_is_empty_arg_err	# Error if not a link.

    li a0, 0			# Init return to false.

    # Check for empty list.
    ld t0, link_val(s1)
    bnez t0, list_is_empty_end

    # List is empty.

    # Check for next error.
    ld t0, link_next(s1)
    bnez t0, list_is_empty_next_err
    
    li a0, 1			# Set return to true.

list_is_empty_end:

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

# Print error, exit.
list_is_empty_next_err:
    la a0, list_is_empty_next_err_str	# Load addr of prefix string.
    excall t0, prtstr

    li a0, 33	# Load return code.
    excall t0, endprg

# Print error, exit.
list_is_empty_arg_err:
    la a0, list_is_empty_arg_err_str
    excall t0, prtstr

    li a0, 32
    excall t0, endprg

# Print inititalization error, exit.
####################################
link_sa_not_inititalized:
    la a0, lnk_str
    excall t0, prtstr

    li a0, 34
    excall t0, endprg

# Print a summary of memory usage.
# In:  Nothing.
# Ret: Nothing.
# SE:  Text to StdOut.
#################################
link_left:
    # Configure stack.
    addi sp, sp, d1n	# Advance sp for stack frame.
    sd ra, 0(sp)	# Save ra.

    # Load link_sa_ptr.
    la a0, link_sa_ptr_addr
    ld a0, 0(a0)
    ld a0, 0(a0)

    excall t0, stack_array_left

    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    addi sp, sp, d1	# Restore sp.

    ret

# Print pstruct name.
#######################
link_print_name:

    # Configure stack.
    addi sp, sp, d1n	# Advance sp for stack frame.
    sd ra, 0(sp)	# Save ra.

    la a0, link_str
    excall t0, prtstr

    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    addi sp, sp, d1	# Restore sp.

    ret

#### Immutable Data ####

# Let the linker store the address of link_sa_ptr.
link_sa_ptr_addr:   .dword link_sa_ptr

# link_init:
link_str:		.asciz  "Link"
link_init_err_str:	.asciz "Link already initialized\n"

# list_pop:
list_pop_arg_err_str:	.asciz	"list_pop: Arg passed is not a link.\n"
list_pop_empty_err_str:	.asciz	"list_pop: empty list.\n"

# list_push:
list_push_arg_err_str:	.asciz	"list_push: Arg passed is not a link.\n"
list_push_type_err_str:	.asciz	"list_push: Value passed is different than other items.\n"

# link_dealloc:
list_dealloc_arg_err_str:	.asciz	"\nlist_dealloc: Arg passed is not a link.\n"

# link_get_val:
link_get_val_arg_err_str:	.asciz	"link_get_val: Arg passed is not a link.\n"

# link_get_next:
link_get_next_arg_err_str:	.asciz	"\nlink_get_next: Arg passed is not a link.\n"

# link_print:
link_print_val_str:	.asciz "[Link: Value: "
link_print_nxt_str:	.asciz ", Next: "
link_print_arg_err_str:		.asciz	"\nlink_print: Arg passed is not a link.\n"

# link_list_dealloc:
link_list_dealloc_arg_err_str:	.asciz	"list_list_dealloc: Arg passed is not a link.\n"

# list_len:
list_len_arg_err_str:	.asciz	"\nlist_len: Arg passed is not a link.\n"

# list_is_empty:
list_is_empty_arg_err_str:	.asciz	"\nlist_is_empty: Arg passed is not a link.\n"
list_is_empty_next_err_str:	.asciz "\nlist_is_empty: Link empty, but next is non-zero\n"

# link_sa_not_inititalized:
lnk_str: 	.asciz "Link stack-array not initialized\n"

# External function addresses.
##############################
prtstr_addr:		.dword prtstr
prtdec_addr:		.dword prtdec
prthex_addr:		.dword prthex
prtchr_addr:		.dword prtchr
prtnl_addr:		.dword prtnl
endprg_addr:		.dword endprg
mem_within_addr:	.dword mem_within
stack_array_alloc_addr:	.dword stack_array_alloc
stack_array_dealloc_addr:	.dword stack_array_dealloc
stack_array_print_addr:	.dword stack_array_print
stack_array_left_addr:	.dword stack_array_left
stack_array_new_addr:	.dword stack_array_new


#### Mutable Data ####

.data 

# Storage for link stack_array struct ptr.
link_sa_ptr:   .dword 0

