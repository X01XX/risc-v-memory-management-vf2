# Implement element struct and methods.
#
# See element struct, below.

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

# Struct element:
        .equ element_id, 	0	# 4 bytes, 1 word. Element struct ID value.
        .equ element_name,	4	# 8 bytes, 2 words. Ptr to element name string. 
        .equ element_atomic_number, 12	# 4 bytes, 1 words. Atomic number.
        .equ element_words,	4

#  Global labels:
	.global element_init
	.global element_new
	.global element_dealloc
	.global element_list_dealloc
	.global element_stack_print
	.global element_print
	.global element_list_print
	
# External labels:
	.extern endprg
	.extern prtchr
	.extern prtstr
	.extern prtdec

        .extern mem_init
        .extern mem_alloc

        .extern stack_array_new
        .extern stack_array_alloc
        .extern stack_array_dealloc
        .extern stack_array_print

	.extern is_link
	.extern link_val
	.extern link_print
	.extern link_get_val
	.extern link_get_next
	.extern link_list_dealloc

# ID to identify a element instance.
	.equ element_id_val, 1153

# Initialize element storage.
# mem_init needs to be called from main before calling this.
#
# In:  a0 contains the number of items to allow for.
# Ret: Nothing.
element_init:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.

    li a1, element_words	# Load number words per item.
    la a2, element_str		# Load stack_array decription ptr.
    jal stack_array_new		# sa struct adr to a1

    # Save element sa ptr.
    la t0, element_sa_ptr
    sd a1, 0(t0)

    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

# Return a new element.
# In:  a0 = Ptr to name string.
#      a1 = Atomic number.
# Ret: a1 = Element instance ptr.
element_new:
    # Configure stack.
    addi sp, sp, d3n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.

    # Save args.
    mv s1, a0			# Save name ptr to s1.
    mv s2, a1			# Save atomic number to s2.

    # Allocate a new element instance, or stack empty.
    la t0, element_sa_ptr
    ld a0, 0(t0)		# Get element stack_array pointer.
    jal stack_array_alloc	# Get a new item into a1, or stack empty.

    # Load values into element instance.
    li t0, element_id_val	# Load the element id value.
    sw t0, element_id(a1)	# Set element ID.
    sd s1, element_name(a1)	# Store element name ptr.
    sw s2, element_atomic_number(a1)	# Store atomic number.

    # Restore stack.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

# Deallocate a element.
# In: a0 is a pointer to an element instance.
# Ret: Nothing.
element_dealloc:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.

    # Check instance ID.
    lw t0, element_id(a0)	# Load instance ID.
    li t1, element_id_val	# Load expected ID.
    bne t0, t1, eid_err		# Error if ne.

    # Deallocate.
    mv a1, a0			# Item ptr to a1.
    la t0, element_sa_ptr
    ld a0, 0(t0)		# Get element stack_array pointer.
    jal stack_array_dealloc	# Add instance back to element stack.

    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

eid_err:
    la a0, eid_err_str
    jal prtstr			# Print error string.

    addi a0, x0, 15		# Load return code.
    jal endprg

# Verify a ptr references a element instance, or halt.
# In: a0 = Ptr to instance.
is_element:
    lw t0, element_id(a0)  # Load instance ID val.
    li t1, element_id_val  # Load expected ID val.

    bne t0, t1, eid_err
    ret

# Accessor to get element name.
# In:  a0 = ptr to element instance.
# Ret: a1 = element name.
element_get_name:
    # Check instance ID.
    lw t0, element_id(a0)       # Load instance ID.
    li t1, element_id_val       # Load expected ID.
    bne t0, t1, eid_err		# Error if ne.

    ld a1, element_name(a0)     # Load element next to return.

    ret

# Accessor to get element atomic_number.
# In:  a0 = ptr to element instance.
# Ret: a1 = element atomic_number.
element_get_atomic_number:
    # Check instance ID.
    lw t0, element_id(a0)       # Load instance ID.
    li t1, element_id_val       # Load expected ID.
    bne t0, t1, eid_err		# Error if ne.

    lw a1, element_atomic_number(a0)     # Load element next to return.

    ret

# Print the element stack.
# In:  Nothing.
# Ret: Nothing.
# Out: Prints info.
element_stack_print:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.

    la t0, element_sa_ptr
    ld a0, 0(t0)		# Load element stack ptr.

    jal stack_array_print	# Print the stack.
   
    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

# Print an element instance.
# In:  a0 = ptr to an element instance.
# Ret: Nothing.
# Out: Prints info.
element_print:
    # Configure stack.
    addi sp, sp, d2n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.

    mv s1, a0			# Save a0.

    # Check instance ID.
    lw t0, element_id(a0)	# Load instance ID.
    li t1, element_id_val	# Load expected ID.
    bne t0, t1, eid_err		# Error if ne.

    li a0, '['
    jal prtchr

    la a0, el_name_str
    jal prtstr

    ld a0, element_name(s1)
    jal prtstr

    la a0, el_an_str
    jal prtstr

    lw a0, element_atomic_number(s1)
    jal prtdec

    li a0, ']'
    jal prtchr

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restare ra.
    addi sp, sp, d2             # Restore sp.

    ret

# Print an element linked list.
# In: a0 = ptr to a link.
#     a1 = ptr to a string to use as a separator.
element_list_print:
    # Configure stack.
    addi sp, sp, d4n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.
    sd s3, d3(sp)		# Save s3.

    # Save args.
    mv s1, a0			# Save link ptr.
    mv s2, a1			# Save separator ptr to s2.

    # Check list arg.
    mv a0, s1			# Load link ptr
    jal is_link			# Check link id.

    li a0, '('			# Print list prefix, left paren.
    jal prtchr

    # Check for empty list.
    mv a0, s1			# Get link value.
    jal link_get_val
    beq a1, x0, epl_loop_end

epl_loop_next:
    mv a0, s1			# Load link value, to a1.
    jal link_get_val
    mv s3, a1

    mv a0, s3			# Print it.
    jal element_print

    mv a0, s1			# Load link next.
    jal link_get_next

    beq a1, x0, epl_loop_end

    mv s1, a1			# Update link next.

    mv a0, s2
    jal prtstr			# Print separator.

    j epl_loop_next

epl_loop_end:
    
    la a0, ')'			# Print list suffix, right paren.
    jal prtchr

    # Restore stack.
    ld s3, d3(sp)		# Restore s2.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d4             # Restore sp.

    ret

# Deallocate a element list.
# In: a0 = link instance ptr.
element_list_dealloc:
    # Configure stack.
    addi sp, sp, d3n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.

   # Save arg.
    mv s1, a0                   # Save link ptr.
    mv s2, a0                   # Save link ptr.

    # Check instance ID.
    mv a0, s1			# Get link value.
    jal is_link

    # Check for empty list.
    mv a0, s1			# Get link value.
    jal link_get_val
    beq a1, x0, edl_loop_end

edl_loop_next:
    mv a0, s1
    jal link_get_val		# Get element ptr in a1.

    # Check element ID.
    lw t0, element_id(a1)
    li t1, element_id_val
    bne t1, t0, eid_err
    
    # Deallocate the element.
    mv a0, a1
    jal element_dealloc

    # Point to the next link.
    mv a0, s1
    jal link_get_next
    mv s1, a1

    beq s1, x0, edl_loop_end

    j edl_loop_next

edl_loop_end:
    # Deallocate the links in the list.
    mv a0, s2
    jal link_list_dealloc

    # Restore stack.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

# Name for element stack_array instance.
element_str:       .asciz  "Element"

el_name_str:	.asciz "Name: "
el_an_str:	.asciz ", AN: "
eid_err_str:	.asciz  "Invalid instance element id"

.data

# Storage for element stack_array struct ptr.
element_sa_ptr:   .dword 0

