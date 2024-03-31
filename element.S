# Implement element struct and methods.
#
# See element struct, below.

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

# Struct element:
        .equ element_id, 	0	# 4 bytes, 1 word. Element struct ID value.
        .equ element_name,	4	# 8 bytes, 2 words. Ptr to element name string. 
        .equ element_atomic_number, 12	# 4 bytes, 1 word. Atomic number.
        .equ element_words,	4

#  Global labels:
	.global element_init
	.global element_new
	.global element_dealloc
	.global element_list_dealloc
	.global element_stack_print
	.global element_print
	.global element_list_print
	.global element_left
	
# ID to identify a element instance.
	.equ element_id_val, 1153

# Initialize element storage.
# mem_init needs to be called from main before calling this.
#
# In:  a0 contains the number of items to allow for.
# Ret: Nothing.
# SE:  Stack array allocated and inititialized.
#############################################################
element_init:

    # Configure stack.
    addi sp, sp, d3n
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)               # Save s1.
    sd s2, d2(sp)               # Save s2.

    mv s1, a0		# Save number items.

    # Load sa ptr addr.
    la s2, element_sa_ptr_addr
    ld s2, 0(s2)

    # Check for previous inititalization.
    ld t0, 0(s2)
    bnez t0, element_init_err

    mv a0, s1			# Load number items.
    li a1, element_words	# Load number words per item.
    la a2, element_str		# Load stack_array decription ptr.
    li a3, element_id_val	# Load struct ID.
    excall t0, stack_array_new		# sa struct adr to a0

    # Save element sa ptr.
    sd a0, 0(s2)

    j element_init_ret

element_init_err:
    la a0, element_init_err_str
    excall t0, prtstr

element_init_ret:
    # Restore stack.
    ld s2, d2(sp)               # Restore s2.
    ld s1, d1(sp)               # Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

# Return a new element.
# In:  a0 = Ptr to name string.
#      a1 = Atomic number.
# Ret: a0 = Element instance ptr.
# SE:  Stack array changed.
#################################
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
    la t0, element_sa_ptr_addr	# Load addr of word containing element sa ptr.
    ld t0, 0(t0)		# Get element stack_array pointer addr.
    ld a0, 0(t0)		# Get element stack_array pointer.

    beqz a0, element_sa_not_inititalized_err

    excall t0, stack_array_alloc	# Get a new item into a0, or stack empty.

    # Load values into element instance.
    #li t0, element_id_val		# Set element ID.
    #sw t0, element_id(a0)
    sd s1, element_name(a0)		# Store element name ptr.
    sw s2, element_atomic_number(a0)	# Store atomic number.

    # Restore stack.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

# Deallocate a element.
# In: a0 is a pointer to an element instance.
# Ret: Nothing.
# SE:  Stack array changed.
##############################################
element_dealloc:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save arg.

    # Check instance ID.
    mv a0, s1
    jal is_element
    beqz a0, element_dealloc_err	# Error if not an element.

    # Deallocate.
    la t0, element_sa_ptr_addr	# Load Element SA ptr.
    ld t0, 0(t0)
    ld a0, 0(t0)

    mv a1, s1			# Load element instance ptr.

    excall t0, stack_array_dealloc	# Add instance back to element stack.

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

element_dealloc_err:
    la a0, element_dealloc_err_str
    excall t0, prtstr			# Print error string.

    addi a0, x0, 35		# Load return code.
    excall t0, endprg

# Check if a ptr references a element instance.
# In: a0 = Ptr to instance.
# Ret: a0 - 1 = true, 0 = false.
# SE:  Nothing.
#######################################################
is_element:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save arg.

    excall t0, mem_within	# Check if in local memory.
    beqz a0, is_element_ret_false

    # Check ID.
    lwu t0, element_id(s1)
    li t1, element_id_val 
    bne t0, t1, is_element_ret_false

    li a0, 1
    j is_element_ret 

is_element_ret_false:
    li a0, 0

is_element_ret:
    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

# Accessor to get element name.
# In:  a0 = ptr to element instance.
# Ret: a0 = element name ptr.
# SE:  Nothing.
#####################################
element_get_name:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save arg.

    # Check instance ID.
    jal is_element
    beqz a0, element_get_name_arg_err		# Error if not an element.

    ld a0, element_name(s1)     # Load element next to return.

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.
    ret

element_get_name_arg_err:
    la a0, element_get_name_arg_err_str
    excall t0, prtstr	# Print error string.

    li a0, 36		# Load return code.
    excall t0, endprg


# Accessor to get element atomic_number.
# In:  a0 = ptr to element instance.
# Ret: a0 = element atomic_number.
# SE:  Nothing.
#######################################
element_get_atomic_number:

   # Configure stack
    addi sp, sp, d2n	# Advance stack pointer.
    sd ra, 0(sp)	# Save ra.
    sd s1, d1(sp)	# Save s1.

    mv s1, a0		# Save arg.

    # Check instance ID.
    jal is_element
    beqz a0, element_get_atomic_number_arg_err		# Error if not an element.

    lwu a0, element_atomic_number(s1)     # Load element next to return.

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d2		# Restore sp.

    ret

element_get_atomic_number_arg_err:
    la a0, element_get_atomic_number_arg_err_str
    excall t0, prtstr	# Print error string.

    li a0, 37		# Load return code.
    excall t0, endprg


# Print the element stack.
# In:  Nothing.
# Ret: Nothing.
# SE:  Text to StdOut.
#################################
element_stack_print:
    # Configure stack.
    addi sp, sp, d1n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.

    # Load Element SA ptr.
    la a0, element_sa_ptr_addr
    ld a0, 0(a0)
    ld a0, 0(a0)

    beqz a0, element_sa_not_inititalized_err

    excall t0, stack_array_print	# Print the stack.
   
    # Restore stack.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d1             # Restore sp.

    ret

# Print an element instance.
# In:  a0 = ptr to an element instance.
# Ret: Nothing.
# SE:  Text to StdOut.
#######################################
element_print:
    # Configure stack.
    addi sp, sp, d2n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.

    mv s1, a0			# Save a0.

    # Check instance ID.
    mv a0, s1
    jal is_element
    beqz a0, element_print_arg_err	# Error if not an element.

    li a0, '['
    excall t0, prtchr

    la a0, el_name_str
    excall t0, prtstr

    ld a0, element_name(s1)
    excall t0, prtstr

    la a0, el_an_str
    excall t0, prtstr

    lwu a0, element_atomic_number(s1)
    excall t0, prtdec

    li a0, ']'
    excall t0, prtchr

    # Restore stack.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restare ra.
    addi sp, sp, d2             # Restore sp.

    ret

element_print_arg_err:
    la a0, element_print_arg_err_str
    excall t0, prtstr			# Print error string.

    li a0, 38		# Load return code.
    excall t0, endprg

# Print an element linked list.
# In:  a0 = ptr to a link.
#      a1 = ptr to a string to use as a separator.
# Ret: Nothing.
# SE:  Text to StdOut.
##################################################
element_list_print:
    # Configure stack.
    addi sp, sp, d3n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.

    # Save args.
    mv s1, a0			# Save link ptr.
    mv s2, a1			# Save separator ptr to s2.

    # Check list arg.
    mv a0, s1			# Load link ptr
    excall t0, is_link			# Check link id.
    beqz a0, element_list_print_arg_err

    li a0, '('			# Print list prefix, left paren.
    excall t0, prtchr

    # Check for empty list.
    mv a0, s1			# Get link value.
    excall t0, link_get_val
    beq a0, x0, epl_loop_end

epl_loop_next:
    mv a0, s1			# Load link value, to a0.
    excall t0, link_get_val

    jal element_print

    mv a0, s1			# Load link next.
    excall t0, link_get_next

    beq a0, x0, epl_loop_end

    mv s1, a0			# Update link next.

    mv a0, s2
    excall t0, prtstr		# Print separator.

    j epl_loop_next

epl_loop_end:
    
    la a0, ')'			# Print list suffix, right paren.
    excall t0, prtchr

    # Restore stack.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

element_list_print_arg_err:
    la a0, element_list_print_arg_err_str
    excall t0, prtstr

    li a0, 39
    excall t0, endprg

# Deallocate a element list.
# In:  a0 = link instance ptr.
# Ret: Nothing.
# SE:  Stack array changed.
###############################
element_list_dealloc:
    # Configure stack.
    addi sp, sp, d3n		# Advance sp for stack frame.
    sd ra, 0(sp)                # Save ra.
    sd s1, d1(sp)		# Save s1.
    sd s2, d2(sp)		# Save s2.

    # Save arg.
    mv s1, a0                   # Save link ptr.

    # Check that arg is a Link.
    mv a0, s1
    excall t0, is_link
    beqz a0, element_list_dealloc_arg_err

    # Check for empty list.
    mv a0, s1			# Get link value.
    excall t0, link_get_val
    beq a0, x0, edl_loop_end

    # Deallocate elements in the list.
    mv s2, a0                   # Init current link ptr.

edl_loop_next:
    mv a0, s2
    excall t0, link_get_val		# Get element ptr in a0.

    # Deallocate the element.
    jal element_dealloc

    # Point to the next link.
    mv a0, s2
    excall t0, link_get_next
    mv s2, a0

    beq s2, x0, edl_loop_end

    j edl_loop_next

edl_loop_end:
    # Deallocate the links in the list.
    mv a0, s1
    excall t0, link_list_dealloc

    # Restore stack.
    ld s2, d2(sp)		# Restore s2.
    ld s1, d1(sp)		# Restore s1.
    ld ra, 0(sp)		# Restore ra.
    addi sp, sp, d3             # Restore sp.

    ret

element_list_dealloc_arg_err:
    la a0, element_list_dealloc_arg_err_str
    excall t0, prtstr

    li a0, 40
    excall t0, endprg

# Print inititalization error and exit.
#######################################
element_sa_not_inititalized_err:
    la a0, element_sa_not_inititalized_err_str
    excall t0, prtstr

    li a0, 41
    excall t0, endprg

# Print a summary of memory usage.
# In:  Nothing.
# Ret: Nothing.
# SE:  Text to StdOut.
###################################
element_left:
    # Configure stack.
    addi sp, sp, d1n	# Advance sp for stack frame.
    sd ra, 0(sp)	# Save ra.

    la a0, element_sa_ptr_addr	# Load addr of word containing element sa ptr.
    ld a0, 0(a0)	# Load ptr to element stack_array addr.
    ld a0, 0(a0)	# Load ptr to element stack_array.

    excall t0, stack_array_left

    # Cleanup stack.
    ld ra, 0(sp)	# Restore ra.
    addi sp, sp, d1	# Restore sp.

    ret

#### Immutable Data ####

element_sa_ptr_addr:   .dword element_sa_ptr

# element_init:
element_str:       .asciz  "Element"
element_init_err_str: .asciz "Element already inititalized\n"

# element_dealloc:
element_dealloc_err_str:	.asciz  "element_dealloc: Arg passed is not an element.\n"

# element_get_name:
element_get_name_arg_err_str:	.asciz  "element_get_name: Arg passed is not an element.\n"

# element_get_atomic_number:
element_get_atomic_number_arg_err_str:	.asciz  "element_get_atomic_number: Arg passed is not an element.\n"

# element_print:
element_print_arg_err_str:	.asciz  "element_print: Arg passed is not an element.\n"
el_name_str:	.asciz "Name: "
el_an_str:	.asciz ", AN: "

# element_list_print:
element_list_print_arg_err_str:	.asciz "element_list_print: Arg passed is not a link.\n"

# element_list_dealloc:
element_list_dealloc_arg_err_str:	.asciz	"element_list_dealloc: Arg passed is not a list.\n"

# element_sa_not_inititalized_err:
element_sa_not_inititalized_err_str: 	.asciz "Element stack-array not initialized\n"

# External function addresses.
################################
prtstr_addr:		.dword prtstr
prtdec_addr:		.dword prtdec
#prthex_addr:		.dword prthex
prtchr_addr:		.dword prtchr
#prtnl_addr:		.dword prtnl
endprg_addr:		.dword endprg
mem_within_addr:	.dword mem_within
link_get_val_addr:	.dword link_get_val
link_get_next_addr:	.dword link_get_next
is_link_addr:		.dword is_link
link_list_dealloc_addr:	.dword link_list_dealloc
stack_array_left_addr:	.dword stack_array_left
stack_array_alloc_addr:	.dword stack_array_alloc
stack_array_dealloc_addr:	.dword stack_array_dealloc
stack_array_print_addr:	.dword stack_array_print
stack_array_new_addr:	.dword stack_array_new


#### Mutable Data ####
.data

# Storage for element stack_array struct ptr.
element_sa_ptr:   .dword 0

