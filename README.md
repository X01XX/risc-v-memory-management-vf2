# risc-v-memory-management-vf2
A simple memory management method for progams written in GNU 64-bit Assembler Language on a VisionFive 2 SBC.

This project may make large Assembler Language programs more practical by enabling/conventionlizing structs, linked lists, allocation and deallocation. 

I'm not using complex combinations of instructions, it should be easy to port.

Define pseudo-structs (pstructs) as a contiguous series of named/labeled field offsets.

Define an array of pstructs, then allocate and deallocate pstructs from the array.

Multiple arrays, of different pstruct size and number, can be made.

A special-purpose stack is paired with each array of pstructs.

The special-purpose stack is initialized with the address of each array pstruct.

Allocation and deallocation is fairly fast because it involves only popping or pushing the stack.

The capacity of each array-stack, is configurable at instance creation.

Within the limit of the array-stack capacity of pstructs (which you set), allocated at the same time, an infinite number of allocations and deallocations are possible.

Allocations, and deallocations, causes increasing disorder of the addresses on the stack, which has no effect on the utility, or speed, of the array-stack.

The example uses a small linked list of pstructs containing information on elements.  The element.S file can be copied and changed for any number of other pstructs.

Deallocate lists, and other pstructs, as soon as they are no longer needed.

Diagnosis of a memory leak can begin with the stack that becomes exhausted.

The first word of every pstruct is set to a unique number, to indicate its type.

Lists have to contain only one type of pstruct.

Instances of stacks may be used without any corresponding array, by running stack_new.

<pre>
See the forth-memory-management project for more development, which may be added here at a later date,
but would make it harder to port.
  
    Guaranteed memory-leak detection.  At program end, check each instance address has been returned to its stack.
  
    Memory usage tuning, how close did each array-stack get to running out of memory?
  
    Allocation counting and display.
  
    Lists with sub-lists and multiple structs, parsing a list from a string.
</pre>


