# risc-v-memory-management-vf2
A simple memory management method for progams written in GNU 64-bit Assembler Language on a VisionFive 2 SBC.

This project may make large Assembler Language programs more practical by enabling/conventionlizing structs, linked lists, allocation and deallocation. 

Define pseudo-structs (pstructs) as a contiguous series of named/labeled field offsets.

Define an array of pstructs, then allocate and deallocate pstructs from the array.

Multiple arrays, of different pstruct size and number, can be made.

A special-purpose stack is paired with each array of pstructs.

The special-purpose stack is initialized with the address of each array pstruct.

Allocation and deallocation is fairly fast because it involves only popping or pushing the stack.

The capacity of each stack-array, is configurable at instance creation.

Within the limit of the stack-array capacity of pstructs (which you set), allocated at the same time, an infinite number of allocations and deallocations are possible.

The entropy of various allocations, and deallocations, appears in the increasing disorder of the addresses on the stack, which has no effect on the utility, or speed, of the stack-array. A win against entropy?

The example uses a small linked list of pstructs containing information on elements.  The element.S file can be copied and changed for any number of other pstructs.

Deallocate lists, and other pstructs, as soon as they are no longer needed.

Diagnosis of a memory leak can begin with the stack that becomes exhausted.

The first word of every pstruct is set to a unique number, to indicate its type.

Lists have to contain only one type of pstruct.

Instances of stacks may be used without any corresponding array, by running stack_new.

If working with pstruct addresses on a stand-alone stack, it can be detected that the last copy of an address has been popped off the stack, by running stack_contains, and therefore it is ready to be deallocated.
