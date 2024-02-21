
.text

	.global _start

	# Word sizes. # Change if a word is not 32 bits, 4 bytes.
	
# External labels:
	.extern mem_init
	.extern mem_left
   
_start:
    # Init alloc-only memory bank.
    jal mem_init

    jal mem_left
    
    # Init links struct alloc/dealloc stack-array memory.
 
    addi a0, x0, 0	# Use 0 return code
    addi a7, x0, 93	# Service code 93 terminates program
    ecall
