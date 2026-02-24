CC = gcc
CFLAGS = -Wall -g
FLEX = flex
BISON = bison

SRC_DIR = .
GEN_DIR = ../generated
BUILD_DIR = ../generated
ROOT_DIR = ..

TARGET = $(ROOT_DIR)/myParser
SOURCES = $(GEN_DIR)/parser.tab.c $(GEN_DIR)/lexer.c
OBJECTS = $(BUILD_DIR)/parser.tab.o $(BUILD_DIR)/lexer.o
GENERATED = $(GEN_DIR)/parser.tab.c $(GEN_DIR)/parser.tab.h $(GEN_DIR)/lexer.c

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $^
	@echo "Build complete! Executable: $(TARGET)"

$(GEN_DIR)/parser.tab.c $(GEN_DIR)/parser.tab.h: $(SRC_DIR)/parser.y
	$(BISON) -d $< -o $(GEN_DIR)/parser.tab.c

$(GEN_DIR)/lexer.c: $(SRC_DIR)/lexer.l $(GEN_DIR)/parser.tab.h
	$(FLEX) -o $@ $<

$(BUILD_DIR)/%.o: $(GEN_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET) $(GENERATED)
	@echo "Clean complete!"

rebuild: clean all

.PHONY: all clean rebuild
