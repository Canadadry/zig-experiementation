#include <testing/testing.h>
#include "token.h"
#include <stdlib.h>

void test_token_init(){
	struct{
		char name[255];
		Token input;
		char exp[100];
} tests[] = {
		{
			"left parenthesis",
			token_init(TYPE_LEFT_PAR,"(",1,0),
			"got type 0, lit '(', len 1, pos 0"
		},
		{
			"litteral too big",
			token_init(
				TYPE_TOO_LONG_NUMBER,
				"123456789012345678901234567890",
				30,
				0
			),
			"got type 11, lit '1234567890123456789012345', len 25, pos 0"
		},
	};
	int len = sizeof(tests)/sizeof(tests[0]);
	for(int i=0;i<len;i++){
		testing_run(tests[i].name);
		char result[500] = {0};
		sprintf(
			result,
			"got type %d, lit '%s', len %d, pos %d",
			tests[i].input.type,
			tests[i].input.literal,
			tests[i].input.len,
			tests[i].input.pos
		);
		assert_string_equals(tests[i].exp,result);
	}
}

UNIT_TEST_FILE(test_token_init)