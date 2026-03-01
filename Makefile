all: flit.c
	$(CC) flit.c -o ./flit/usr/bin/flt -Wall -Wextra -O3 -pedantic -std=c99

clean:
	rm -f ./flit/usr/bin/flt
