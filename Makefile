CC = clang
CFLAGS = -Wall -Os
AR = ar
ARFLAGS = rcs
LIB = libchatgui.a
OBJ = $(patsubst %.m, %.o, $(wildcard *.m))

%.o: %.m
	$(CC) $(CFLAGS) -c $<

$(LIB): $(OBJ)
	$(AR) $(ARFLAGS) $@ $^

.PHONY: example clean
example: $(LIB)
	$(CC) -L. -lchatgui -framework Cocoa -o example example.c

clean:
	rm -f $(OBJ) $(LIB) example
