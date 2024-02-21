main: main.o memory.o tools.o
	ld -o main main.o memory.o tools.o
memory.o: memory.S
	as -o memory.o memory.S
main.o: main.S
	as -o main.o main.S
tools.o: tools.S
	as -o tools.o tools.S
