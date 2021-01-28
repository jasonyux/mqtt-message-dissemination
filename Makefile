CC = gcc
CFLAGS = -Wall -g
LDLIBS = -lmosquitto

client: client.o

client.o: client.c

subscriber: subscriber.o

subscriber.o: subscriber.c

.PHONY: all

all: client subscriber
