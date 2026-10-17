CROSS_COMPILE ?= 
CC = $(CROSS_COMPILE)gcc
TARGET = writer

.PHONY = all clean

all: $(TARGET)

$(TARGET): writer.c
	$(CC) -o $@ $<

clean:
	rm -f $(TARGET)