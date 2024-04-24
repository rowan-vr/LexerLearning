CFLAGS+=-Werror -Wall -Wextra -pthread -D_GNU_SOURCE -ggdb -DYY_READ_BUF_SIZE=1
LFLAGS+=--header-file=test.h --reentrant

test: test.c

test.c: test.l