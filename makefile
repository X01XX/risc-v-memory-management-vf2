main: main.o memory.o tools.o stack.o stack_array.o
	ld -o main main.o memory.o tools.o stack.o stack_array.o
memory.o: memory.S
	as -o memory.o memory.S
main.o: main.S
	as -o main.o main.S
tools.o: tools.S
	as -o tools.o tools.S
stack.o: stack.S
	as -o stack.o stack.S
stack_array.o: stack_array.S
	as -o stack_array.o stack_array.S
