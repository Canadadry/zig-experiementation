#ifndef __TOKEN_HEADERS__
#define __TOKEN_HEADERS__
#define MAX_LITERAL_LEN 25

typedef enum {
TYPE_LEFT_PAR,TYPE_RIGHT_PAR,
TYPE_PLUS,STAR,TYPE_SLASH,TYPE_MINUS,
TYPE_TYPE_DOUBLE_STAR,TYPE_DOUBLE_SLASH,TYPE_PERCENT,
TYPE_NUMBER,
TYPE_ILLEGAL,TYPE_TOO_LONG_NUMBER,
TYPE_EOF
} TokenType ;

typedef struct{
	TokenType type;
    char literal[MAX_LITERAL_LEN];
    int len;
    int pos;
} Token;

Token token_init(TokenType token_type, char* lit, int len ,int pos);

#endif