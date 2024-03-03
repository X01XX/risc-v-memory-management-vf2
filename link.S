# Implement link struct and methods.
#
# See link struct, below.

.text

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

# External labels:
	.extern endprg		# End program.
	.extern prtnl		# Print newline.
	.extern prthex		# Print number in base 16.
	.extern	prtstr		# Print a string.

        .extern mem_init
        .extern mem_alloc

        .extern stack_array_new
        .extern stack_array_alloc
        .extern stack_array_dealloc
        .extern stack_array_print

# ID to identify a link instance.
	.equ link_id_val, 1319

# Initialize link storage.
# mem_init needs to be called from main before calling this.
#
# In:  a0 contains the number of items to allow for.
# Ret: Nothing.
link_init:
    # Configure stack.
    addi sp, sp, d1n	# Advance sp for stack frame.
    sd ra, 0(sp)        # Save ra.

    la t0, link_sa_ptr	# Load addr of word containing the sa ptr.
    ld t1, 0(t0)	# Check for previous inititalization.
    bnez t1, link_init_err

    li a1, link_words   # Load number words per item.
    la a2, link_str     # Load stack_array decription ptr.
    jal stack_array_new # sa struct adr to a1

    # Save link sa ptr.
    la t0, link_sa_ptr
    sd a1, 0(t0)

    j link_init_ret

link_init_err:
    la a0, link_init_err_str
    jal prtstr

link_init_ret:
    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    addi sp, sp, d1     # Restore sp.

    ret

# Return a new link.
# In:  a0 = Link value.
#      a1 = Link next.
# Ret: a1 = Link instance ptr.
link_new:
    # Configure stack.
    addi sp, sp, d3n
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)               # Save s1.
    sd s2, d2(sp)               # Save s2.

    # Save args.
    mv s1, a0                   # Save link value to s1.
    mv s2, a1                   # Save link next to s2.

    # Allocate a new link instance, or stack empty.
    la t0, link_sa_ptr
    ld a0, 0(t0)		# Get link stack_array pointer.
    beqz a0, lnk_not_inititalized

    jal stack_array_alloc	# Get a new item into a1, or stack empty.

    # Load values to instance.
    li t0, link_id_val		# Load the link id value.
    sw t0, link_id(a1)		# Set link ID in returned instance.
    sd s1, link_val(a1)		# Store link value prt.
    sd s2, link_next(a1)	# Store link next prt.

    # Restore stack.
    ld s2, d2(sp)               # Restore s2.
    ld s1, d1(sp)               # Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

# Return an empty list, a link with value 0, next 0.
# In:  Nothing.
# Ret: a1 = empty list.
list_new:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.

    li a0, 0
    li a1, 0
    jal link_new

    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

# Pop a value from a list.
#
# In:  a0 = List (link) ptr.
# Ret: a1 = Value ptr.
list_pop:
    # Configure stack.
    addi sp, sp, d4n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.
    sd s3, d3(sp)		# Save s3.

    # Save arg.
    mv s1, a0			# Save link ptr.

    # Check instance ID.
    lw t0, link_id(s1)       	# Load instance ID.
    li t1, link_id_val		# Load expected ID.
    bne t0, t1, lid_err         # Error if ne.

    # Check if empty list.
    mv a0, s1
    jal list_is_empty
    bne a1, x0, lpo_err

    # Save link 0 value to return.
    ld s2, link_val(s1)

    # Save link 1 ptr
    ld s3, link_next(s1)

    # Check for last link.
    beq s3, x0, lpo_last

    # Move info from link 1 to link 0.
    ld t0, link_val(s3)
    sd t0, link_val(s1)
    ld t0, link_next(s3)
    sd t0, link_next(s1)

    # Dealloc link 1.
    mv a0, s3
    jal link_dealloc

    j lpo_end

lpo_last:
    sd x0, link_val(s1)		# Change first link to empty list, link_next already 0.
    
lpo_end:
    # Load value to return.
    mv a1, s2

    # Restore stack.
    ld s3, d3(sp)		# Restore s3.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d4             # Restore sp.

    ret
    
lpo_err:
    la a0, lpo_err_str	# Load addr of prefix string.
    jal prtstr

    addi a0, x0, 11	# Load return code.
    jal endprg

# Push a value onto a list of structs, sharing the same ID value.
# In:  a0 = a link ptr.
#      a1 = value ptr. a1 = struct value, with ID in first word.
# Ret: Nothing.
list_push:
    # Configure stack.
    addi sp, sp, d3n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.

    # Save args.
    mv s1, a0			# Save link ptr.
    mv s2, a1			# Save value ptr.

    # Check instance ID.
    lw t0, link_id(s1)       	# Load instance ID.
    li t1, link_id_val		# Load expected ID.
    bne t0, t1, lid_err         # Error if ne.

    # Check for empty list.
    mv a0, s1
    jal list_is_empty
    bne a1, x0, lp_empty_list
    
    # List is not empty.

    # Check value ids is equal to other IDs in the list.
    ld t0, link_val(s1)		# Get first link value.
    lw t0, 0(t0)		# Get value ID.

    lw t1, 0(s2)		# Get value-to-push ID.
    bne t0, t1, lp_id_err	# Jump to error code.

    # Get new link, a1
    jal link_new

    # Move first link info into the new link.
    ld t0, link_val(s1)
    sd t0, link_val(a1)
    ld t0, link_next(s1)
    sd t0, link_next(a1)

    # Make first link next point to new link.
    sd a1, link_next(s1)

    # Make first link value equal new value.
    sd s2, link_val(s1)   

    j lp_end

lp_empty_list:
    sd s2, link_val(s1)		# Store value in first link.

lp_end:
    # Restore stack.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

lp_id_err:
    la a0, lp_id_err_str	# Load addr of prefix string.
    jal prtstr

    addi a0, x0, 12	# Load return code.
    jal endprg

# Deallocate a link.
# In: a0 contains a pointer to a link instance.
# Ret: Nothing.
link_dealloc:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.

    # Check instance ID.
    lw t0, link_id(a0)		# Load instance ID.
    li t1, link_id_val		# Load expected ID.
    bne t0, t1, lid_err		# Error if ne.

    # Deallocate.
    mv a1, a0			# Item ptr to a1.

    la t0, link_sa_ptr
    beqz t0, lnk_not_inititalized

    ld a0, 0(t0)		# Get link stack_array pointer.
    jal stack_array_dealloc	# Add instance back to link stack.

    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

lid_err:
    la a0, lid_err_str	# Load addr of prefix string.
    jal prtstr

    addi a0, x0, 13	# Load return code.
    jal endprg

# Verify a ptr references a link instance, or halt.
# In: a0 = Ptr to instance.
is_link:
    lw t0, link_id(a0)	# Load instance ID val.
    li t1, link_id_val	# Load expected ID val.

    bne t0, t1, lid_err
    ret

# Accessor to get link value.
# In:  a0 = ptr to link instance.
# Ret: a1 = link value.
link_get_val:
    # Check instance ID.
    lw t0, link_id(a0)       	# Load instance ID.
    li t1, link_id_val		# Load expected ID.
    bne t0, t1, lid_err         # Error if ne.

    ld a1, link_val(a0)		# Load link value to return.

    ret

# Accessor to get link next.
# In:  a0 = ptr to link instance.
# Ret: a1 = link next.
link_get_next:
    # Check instance ID.
    lw t0, link_id(a0)       	# Load instance ID.
    li t1, link_id_val		# Load expected ID.
    bne t0, t1, lid_err         # Error if ne.

    ld a1, link_next(a0)	# Load link next to return.

    ret

# Print the link stack.
# In:  Nothing.
# Ret: Nothing.
# Out: Prints info.
link_stack_print:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.

    la t0, link_sa_ptr
    ld a0, 0(t0)		# Load link stack ptr.
    beqz a0, lnk_not_inititalized


    jal stack_array_print	# Print the stack.
   
    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

# Print an link instance.
# In:  a0 = ptr to a link instance.
# Ret: Nothing.
# Out: Prints info.
link_print:
    # Configure stack.
    addi sp, sp, d2n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.

    mv s1, a0			# Save a0.

    # Check instance ID.
    lw t0, link_id(s1)       	# Load instance ID.
    li t1, link_id_val		# Load expected ID.
    bne t0, t1, lid_err         # Error if ne.

    li a0, '['			# Load left bracket value.
    jal prtchr

    la a0, lp_val_str	# Load addr of prefix string.
    jal prtstr

    ld a0, link_val(s1)
    jal prthex

    la a0, lp_nxt_str	# Load addr of prefix string.
    jal prtstr

    ld a0, link_next(s1)
    jal prthex

    li a0, ']'		# Load right bracket value.
    jal prtchr

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2             # Restore sp.

    ret

# Deallocate a linked list.
# Clear values from the list before calling this.
# In: a0 = ptr to a link instance.
link_list_dealloc:
    # Configure stack.
    addi sp, sp, d3n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.

    # Save arg.
    mv s1, a0			# Save link ptr.

    # Check instance ID.
    lw t0, link_id(s1)       	# Load instance ID.
    li t1, link_id_val		# Load expected ID.
    bne t0, t1, lid_err         # Error if ne.

ldl_loop_next:
    mv s2, s1			# Save current link ptr.

    ld s1, link_next(s1)	# Load link next.

    mv a0, s2			# Dealloc current link.
    jal link_dealloc

    beq s1, x0, ldl_loop_end

    j ldl_loop_next

ldl_loop_end:
    
    # Restore stack.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

# Return the length of a list.
# In:  a0 = ptr to a link instance.
# Ret: a1 = list length.
list_len:
    # Configure stack.
    addi sp, sp, d2n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.

    # Check instance ID.
    lw t0, link_id(a0)       	# Load instance ID.
    li t1, link_id_val		# Load expected ID.
    bne t0, t1, lid_err         # Error if ne.

    mv s1, a0			# Save link ptr.

    # Check for empty list.
    jal list_is_empty
    bne a1, x0, ll_empty

    li a1, 0			# Init counter.

ll_loop_next:
    addi a1, a1, 1		# Increment counter.

    ld s1, link_next(s1)	# Load link next.

    beq s1, x0, ll_end		# Exit loop in no more links.

    j ll_loop_next

ll_empty:
    li a1, 0			# Load length to return.

ll_end:
    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2             # Restore sp.

    ret

# Return 1 if a list is empty, otherwise return 0.
# In:  a0 = ptr to a link instance.
# Ret: a1 = 1 or 0.
list_is_empty:

    # Check instance ID.
    lw t0, link_id(a0)       	# Load instance ID.
    li t1, link_id_val		# Load expected ID.
    bne t0, t1, lid_err         # Error if ne.

    li a1, 0			# Init return to false.

    # Check for empty list.
    ld t0, link_val(a0)
    bne t0, x0, lie_end

    li a1, 1			# Set return to true.

    # Check for next error.
    ld t0, link_next(a0)
    beq t0, x0, lie_end
    
    la a0, next_err_str	# Load addr of prefix string.
    jal prtstr

    addi a0, x0, 14	# Load return code.
    jal endprg

lie_end:

    ret

# Print inititalization error and exit.
lnk_not_inititalized:
    la a0, lnk_str
    jal prtstr

    li a0, 17
    jal endprg

lnk_str: 	.asciz "Link stack-array not initialized\n"
next_err_str:	.asciz "\nLink empty, but next non-zero"
lpo_err_str:	.asciz	"\nList_pop: empty list."
lp_id_err_str:	.asciz	"List_push: Invalid struct ID."
lid_err_str:    .asciz  "Invalid instance link id"
link_str:       .asciz  "Links"
lp_val_str:	.asciz "Value: "
lp_nxt_str:	.asciz ", Next: "
link_init_err_str: .asciz "Link already initialized\n"

.data 

# Storage for link stack_array struct ptr.
link_sa_ptr:   .dword 0




