CC = gcc
CFLAGS = -Wall -g
LDLIBS = -lmosquitto

.PHONY: all

all: client subscriber

client: client.o

client.o: client.c

subscriber: subscriber.o

subscriber.o: subscriber.c

