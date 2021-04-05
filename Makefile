CC = gcc
CFLAGS = -Wall -g
LDLIBS = -lmosquitto

.PHONY: all clean

all: publisher subscriber subscriber_100 publisher_args subscriber_args

clean:
	rm -f *.o publisher subscriber subscriber_100 publisher_args subscriber_args

publisher: publisher.o

publisher.o: publisher.c

subscriber: subscriber.o

subscriber.o: subscriber.c

subscriber_100: subscriber_100.o

subscriber_100.o: subscriber_100.c

publisher_args: publisher_args.c

subscriber_args: subscriber_args.c
