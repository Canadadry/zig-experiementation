#include "token.h"
#include <string.h>

Token token_init(TokenType token_type, char* lit, int len ,int pos){
	Token token = {
		token_type,
		{0},
		len,
		pos,
	};
	if(token.len > MAX_LITERAL_LEN){
		token.len = MAX_LITERAL_LEN;
	}
	memcpy(&token.literal,lit,token.len);
	return token;
}
