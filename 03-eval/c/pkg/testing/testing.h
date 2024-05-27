#ifndef TESTING_H
#define TESTING_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

typedef struct {
    void (*func)(void);
    const char* name;
} TestEntry;

static const char* current_test_name = NULL;
static const char* current_function_name = NULL;
static int test_failed = 0;

// Macros for counting and iterating over variadic arguments
#define CONCAT_INTERNAL(x, y) x##y
#define CONCAT(x, y) CONCAT_INTERNAL(x, y)

#define EXPAND(x) x
#define FOR_EACH(action, separator, ...) \
    EXPAND(CONCAT(FOR_EACH_, COUNT_ARGS(__VA_ARGS__)) (action, separator, __VA_ARGS__))

#define COUNT_ARGS(...) \
    EXPAND(ARG_COUNT_INTERNAL(0, ##__VA_ARGS__, 5, 4, 3, 2, 1, 0))
#define ARG_COUNT_INTERNAL(_0, _1, _2, _3, _4, _5, N, ...) N

#define FOR_EACH_1(action, separator, x) action(x)
#define FOR_EACH_2(action, separator, x, ...) action(x) separator FOR_EACH_1(action, separator, __VA_ARGS__)
#define FOR_EACH_3(action, separator, x, ...) action(x) separator FOR_EACH_2(action, separator, __VA_ARGS__)
#define FOR_EACH_4(action, separator, x, ...) action(x) separator FOR_EACH_3(action, separator, __VA_ARGS__)
#define FOR_EACH_5(action, separator, x, ...) action(x) separator FOR_EACH_4(action, separator, __VA_ARGS__)

#define TEST_ENTRY(func) {func, #func},

// Main function macro to setup and run tests
#define UNIT_TEST_FILE(...) \
    int main() { \
        TestEntry tests[] = { \
            FOR_EACH(TEST_ENTRY, , __VA_ARGS__) \
        }; \
        int len =  sizeof(tests) / sizeof(tests[0]); \
        for (int i = 0; i < len ; i++) { \
            current_function_name = tests[i].name; \
            current_test_name = tests[i].name; \
            tests[i].func(); \
            if (test_failed) return 1; \
        } \
    	printf("test passed"); \
        return 0; \
    }

void testing_run(const char* test_name) {
    current_test_name = test_name;
}

void assert_string_equals(const char* expected, const char* actual) {
    if (strcmp(expected, actual) != 0) {
        printf("%s/%s Expected \n\t%s\nbut got \n\t%s\n", current_function_name, current_test_name, expected, actual);
        test_failed = 1;
        exit(1);
    }
}

#endif
