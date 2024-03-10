OBJS = main.o memory.o tools.o stack.o stack_array.o link.o element.o

main: $(OBJS)
	ld -o main $(OBJS)

%.o : %.S
	as $< -o $@

