
A demonstration of memory management, in RISC-V Assembler Language.

A stack is paired with an array, to allow:

   Allocation: Pop an address off the stack.

   Deallocation: Push an address onto the stack.

The stack pointer is stored in memory, not in a dedicated register.
This allows any number of stack-arrays, without using up registers.

Allocation is very fast.

Commenting out an error check, and memory zeroing, could make deallocation as fast as allocation,
with greater risk.  Possibly this could be done with a debug flag and conditional compiling.

Function to file:

Allocate-only memory: memory.a

   You set the maximum available memory.

Allocate-deallocate memory: stack.a, stack_array.a

   You set the maximum number of items in the array, and the item size, separately, for each instance.

   An instance supports one kind of struct, so multiple instances for multiple structs.

Linked list struct, memory, methods: link.a

Example struct that can be put in a list: element.a

   Can be copied and changed, once for each of any number of structs.

   
To run:

make

./main


Return codes:

Main:

    0  - OK

Memory:

  mem_alloc:

    1  - Request for zero memory.

    2  - Out of memory, request cannot be satisfied.

Stack:

  stack_new:

    3  - Request for zero word stack.

  stack_push:

    4  - Stack full.

  stack_pop:

    5  - Stack empty.

  check_name:

    6  - Name has zero length.

    7  - Unprintable character in name. (maybe name is not ended with a zero?)

Stack_array:

  stack_array_new:

    8  - Number items is zero.

    9  - Number words, per item, is zero.

  stack_array_dealloc:

    10 - Stack already contains address to be deallocated.

Link:

  list_pop:

    11 - List empty.

  list_push:

    12 - Invalid link ID.  (pushing a non-link struct, invalid address?)

  link_dealloc:

    13 - Invalid link ID.  (deallocating a non-link struct, invalid address?)
   
  list_is_empty:

    14 - List is empty, val = 0, but next is not = 0?

Element:

  element_dealloc:

    15 - Invalid element ID.  (pushing a non-link struct, invalid address?)

