CC=gcc
CFLAGS=-Wall -g
INCLUDES=-I./pkg

# Spécification des chemins pour les fichiers objet et les binaires
OBJ_DIR=.cache/object
BIN_DIR=.cache/bin

# S'assurer que les répertoires existent
$(shell mkdir -p $(OBJ_DIR))
$(shell mkdir -p $(BIN_DIR))

all: test

test: $(OBJ_DIR)/token_test.o $(OBJ_DIR)/token.o
	$(CC) $(CFLAGS) $(INCLUDES) $(OBJ_DIR)/token_test.o $(OBJ_DIR)/token.o -o $(BIN_DIR)/run_tests
	$(BIN_DIR)/run_tests

# Cible pour compiler token_test.o
$(OBJ_DIR)/token_test.o: src/token_test.c src/token.h
	$(CC) $(CFLAGS) $(INCLUDES) -c src/token_test.c -o $(OBJ_DIR)/token_test.o

# Cible pour compiler token.o
$(OBJ_DIR)/token.o: src/token.c src/token.h
	$(CC) $(CFLAGS) $(INCLUDES) -c src/token.c -o $(OBJ_DIR)/token.o

clean:
	rm -rf .cache

.PHONY: all clean test