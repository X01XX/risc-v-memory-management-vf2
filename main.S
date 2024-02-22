
.text
	.global _start

# External labels:
	.extern mem_init
	.extern mem_left
	.extern mem_alloc

   	.extern nu2h

	.extern stack_new
	.extern stack_push
	.extern stack_pop
	.extern stack_print
	.extern stack_contains
	
	.extern stack_array_new
	.extern stack_array_deallo
	.extern stack_array_alloc
	.extern stack_array_print
   	
_start:
    # Init alloc-only memory bank.
    jal mem_init

    jal mem_left
    
    li a0, 5		# Number items.
    li a1, 3		# Number words in items.
    la a2, stack_name
    jal stack_array_new # Allocate/Init stack_array.
    mv s1, a1		# Save stack ptr.

    mv a0, s1
    jal stack_array_print

    mv a0, s1
    jal stack_array_alloc
    mv s2, a1

    jal pcr
    mv a0, s2
    jal nu2h
    jal pcr

    mv a0, s1
    jal stack_array_print

    mv a0, s1
    mv a1, s2
    jal stack_array_dealloc

    mv a0, s1
    jal stack_array_print

    mv a0, s1
    mv a1, s2
    jal stack_array_dealloc


#    li a0, 2		# Num words.
#    la a1, stack_name	# Name ptr.
#    jal stack_new
#    mv s1, a1		# Save stack ptr
#
#    jal mem_left
#    
#    mv a0, s1
#    jal stack_print
#    
#    mv a0, s1
#    li a1, 34
#    jal stack_push
#
#    mv a0, s1
#    jal stack_print
#    
#    mv a0, s1
#    li a1, 17
#    jal stack_push
#
#    mv a0, s1
#    jal stack_print
#    
#    mv a0, s1
#    li a1, 35
#    jal stack_contains
#    mv a0,a1
#    jal nu2d
#    jal pcr

    # Exit program
    addi a0, x0, 0	# Use 0 return code
    addi a7, x0, 93	# Service code 93 terminates program
    ecall

stack_name: .asciz "fish"
