CC = gcc
DEBUG = -g
CFLAGS = -c $(DEBUG)
LFLAGS = $(DEBUG)

history_access.o : history_access.c
	$(CC) $(CFLAGS) history_access.c

clean:
	\rm *.o
