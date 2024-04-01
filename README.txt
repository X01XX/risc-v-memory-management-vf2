
A demonstration of memory management, in RISC-V Assembler Language.

A stack is paired with an array, to allow:

   Allocation: Pop an address off the stack.

   Deallocation: Push an address onto the stack.

The stack pointer is stored in memory, not in a dedicated register.
This allows any number of stack-arrays, without using up registers.

Allocation is very fast.

Commenting out memory zeroing, could make deallocation as fast as allocation,
with greater risk.  See the zero_memory .equ at the begining of stack_array.S.

Function to file:

Allocate-only memory: memory.a

   You set the maximum available memory, see the first equ in the file.

Allocate-deallocate memory: stack.a, stack_array.a

   You set the maximum number of items in the array, and the item size, separately, for each instance.

   An instance supports one kind of struct, so multiple instances for multiple structs.

   Deallocation can be made faster by commenting out the first equ in the file.

Linked list struct, memory, methods: link.a

Example struct that can be put in a list: element.a

   Can be copied and changed, once for each of any number of structs.

   
To run:

make

./main


Return codes ( A descriptive text will, print for an error ):

Main:

    0  - OK

Memory:

  mem_alloc:

    1  - Request for zero memory.

    2  - Out of memory, request cannot be satisfied.


  varies:

    3 - Local memory not initialized.

Stack:

  stack_new:

    4  - Request for zero word stack.

  stack_push:

    5  - Arg passed not a stack ptr.

    6  - Stack full.

  stack_pop:

    7  - Arg passed not a stack ptr.

    8  - Stack empty.

  check_name:

    9  - Name has zero length.

    10 - Unprintable character in name. (maybe name is not ended with a zero?)

  stack_print_name:

    11 - Arg passed not a stack ptr.

  stack_print

    12 - Arg passed not a stack ptr.

  stack_left

    13 - Arg passed not a stack ptr.

  stack_contains:

    14 - Arg passed not a stack ptr.

Stack_array:

  stack_array_new:

    15 - Number items is zero.

    16 - Number words, per item, is zero.

    42 - Invalid, zero, struct ID.

  stack_array_print:

    17 - Arg passed not a stack ptr.

  stack_array_alloc:

    18 - Arg passed not a stack ptr.

  stack_array_dealloc:

    19 - Arg passed not a stack ptr.

    20 - Stack already contains address to be deallocated.

  stack_array_left:

    21 - Arg passed not a stack ptr.

Link:

  list_pop:

    22 - Arg passed not a stack ptr.

    23 - List empty.

  list_push:

    24 - Arg passed not a stack ptr.

    25 - Pushing item of a different type than is already in the list.

  link_dealloc:

    26 - Arg passed not a stack ptr.

  link_get_val:

    27 - Arg passed not a stack ptr.

  link_get_next:

    28 - Arg passed not a stack ptr.

  link_print:

    29 - Arg passed not a stack ptr.

  link_list_dealloc:

    30 - Arg passed not a stack ptr.

  list_len:

    31 - Arg passed not a stack ptr.

  list_is_empty:

    32 - Arg passed not a stack ptr.

    33 - List is empty, val = 0, but next is not = 0?

  varies:

    34 - Link stack-array not initialized.

Element:

  element_dealloc:

    35 - Arg passed not a stack ptr.

  element_get_name:

    36 - Arg passed not a stack ptr.

  element_get_atomic_number:

    37 - Arg passed not a stack ptr.

  element_print:

    38 - Arg passed not a stack ptr.

  element_list_print:

    39 - Arg passed not a stack ptr.

  element_list_dealloc:

    40 - Arg passed not a stack ptr.

  varies:

    41 - Element stack-array not initialized.

