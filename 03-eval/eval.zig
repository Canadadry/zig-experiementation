const std = @import("std");

const maxLiteralLen = 25;

const TokenType = enum{
	left_par,right_par,
	plus,star,slash,minus,
	double_star,double_slash,percent,
	number,
	illegal,too_long_number,
	eof,
};

const Token = struct{
    type: TokenType,
    literal: [maxLiteralLen]u8,
    pos: usize,

    fn init(typ: TokenType, lit: []const u8, pos: usize) Token {
        var literal: [maxLiteralLen]u8 = undefined;
        const len = @min(lit.len, maxLiteralLen);
        @memcpy( literal[0..len], lit);
        if (len < maxLiteralLen) {
            @memset(literal[len..], 0);
        }
        return Token{
            .type = typ,
            .literal = literal,
            .pos = pos,
        };
    }
};

const Bound = struct{
    start: usize,
    end: usize,
};

const Lexer = struct{
    source:  []const u8,
    current: usize,
    read:    usize,
    ch:      u8,

    pub fn init(source:[]const u8) Lexer{
        var l= Lexer{
            .source=source,
            .current=0,
            .read=0,
            .ch=0,
        };
        l.readChar();
        return l;
    }

    pub fn getNextToken(l:*Lexer)Token{
		while(isWhiteSpace(l.ch)){
			l.readChar();
		}
		var tok = Token.init(.eof,"",l.current);
		switch(l.ch){
			0 => {},
			'('=>{
				tok.type = .left_par;
			},
			')'=>{
				tok.type = .right_par;
			},
			'+'=>{
				tok.type = .plus;
			},
			'-'=>{
				tok.type = .minus;
			},
			'%'=>{
				tok.type = .percent;
			},
			'*'=>{
				tok.type = .star;
				if(l.peekChar() == '*'){
					l.readChar();
					tok = Token.init(.double_star,"**",tok.pos);
				}
			},
			'/'=>{
				tok.type = .slash;
				if(l.peekChar() == '*'){
					l.readChar();
					tok = Token.init(.double_slash,"//",tok.pos);
				}
			},
			else=>{
				tok.type = .illegal;
				if(isNumeric(l.ch)){
					tok.type = .number;
					var bound = l.readNumericBound();
					var len = bound.end-bound.start;
					if (len>maxLiteralLen){
						tok.type = .too_long_number;
						bound.end = bound.start+maxLiteralLen-1;
						len=maxLiteralLen;
					}
					@memcpy( tok.literal[0..len],l.source[bound.start..bound.end], );
				}
			},
		}
		l.readChar();

		return tok;
    }
    pub fn readChar(l:*Lexer)void {
        l.ch = l.peekChar();
        l.current = l.read;
        l.read=l.read+1;
    }

    pub fn peekChar(l:*Lexer) u8 {
        var ch:u8=0;
	    if(l.read < l.source.len){
            ch = l.source[l.read];
        }
        return ch;
    }

    fn readNumericBound(l:*Lexer) Bound {
        var bound = Bound{.start=l.current,.end=l.current+1};
    	while(isNumeric(l.ch)){
    		l.readChar();
    	}
    	bound.end = l.current;
    	return bound;
    }
};

pub fn isWhiteSpace(ch:u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

pub fn isNumeric(ch:u8) bool {
    return ch >= '0' and ch <= '9' and ch == '.';
}

test "lexer get all tokens" {
    const testedString = "()+* /-**//\n12.32%#123456789012345678901234567890";
    const expectedTokens = [_]Token{
        Token.init(.left_par, "(",0),
        Token.init(.right_par, ")",1),
        Token.init(.plus, "+",2),
        Token.init(.star, "*",3),
        Token.init(.slash, "/",5),
        Token.init(.minus, "-",6),
        Token.init(.double_star, "**",7),
        Token.init(.double_slash, "//",9),
        Token.init(.number, "12.32",12),
        Token.init(.percent, "%",17),
        Token.init(.illegal, "#",18),
        Token.init(.too_long_number, "1234567890123456789012345",19),
        Token.init(.eof, "",49),
    };

    var lexer = Lexer.init(testedString);
    var i:usize = 0;
    while (true) : (i+=1) {
        var tok = lexer.getNextToken();
        if (
            tok.type !=  expectedTokens[i].type
            or !std.mem.eql(u8,&tok.literal,&expectedTokens[i].literal)
        ) {
            std.debug.print("failed at \"{d}\"\nexp: \"{}\",\ngot: \"{}\"\n", .{ i,expectedTokens[i],tok });
            return error.TestFailure;
        }
        if(tok.type == .eof){
            break;
        }
    }
    if(i!=expectedTokens.len){
        std.debug.print("failed found \"{d}\" token want \"{d}\"\n", .{ i,expectedTokens.len });
        return error.TestFailure;
    }
}