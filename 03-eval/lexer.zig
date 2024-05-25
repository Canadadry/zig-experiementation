const std = @import("std");
const token = @import("token.zig");


const Bound = struct{
    start: usize,
    end: usize,
};

pub const Lexer = struct{
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

    pub fn getNextToken(l:*Lexer)token.Token{
		while(isWhiteSpace(l.ch)){
			l.readChar();
		}
		var tok = token.Token.init(.eof,"",l.current);
		tok.literal[0]=l.ch;
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
					tok = token.Token.init(.double_star,"**",tok.pos);
				}
			},
			'/'=>{
				tok.type = .slash;
				if(l.peekChar() == '/'){
					l.readChar();
					tok = token.Token.init(.double_slash,"//",tok.pos);
				}
			},
			else=>{
				tok.type = .illegal;
				if(isNumeric(l.ch)){
					tok.type = .number;
					var bound = l.readNumericBound();
					var len = bound.end-bound.start;
					if (len>token.maxLiteralLen){
						tok.type = .too_long_number;
						bound.end = bound.start+token.maxLiteralLen-1;
						len=token.maxLiteralLen-1;
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
     	l.current -=1;
     	l.read -=1;
    	return bound;
    }
};

pub fn isWhiteSpace(ch:u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

pub fn isNumeric(ch:u8) bool {
    return  (ch >= '0' and ch <= '9') or ch == '.';
}

test "lexer get all tokens" {
    const testedString = "()+* /-**//\n12.32%#123456789012345678901234567890";
    const expectedTokens = [_]token.Token{
        token.Token.init(.left_par, "(",0),
        token.Token.init(.right_par, ")",1),
        token.Token.init(.plus, "+",2),
        token.Token.init(.star, "*",3),
        token.Token.init(.slash, "/",5),
        token.Token.init(.minus, "-",6),
        token.Token.init(.double_star, "**",7),
        token.Token.init(.double_slash, "//",9),
        token.Token.init(.number, "12.32",12),
        token.Token.init(.percent, "%",17),
        token.Token.init(.illegal, "#",18),
        token.Token.init(.too_long_number, "123456789012345678901234",19),
        token.Token.init(.eof, "",49),
    };

    var lexer = Lexer.init(testedString);
    var i:usize = 0;
    while (true)  {
        var tok = lexer.getNextToken();
        if (
            tok.type !=  expectedTokens[i].type
            or !std.mem.eql(u8,&tok.literal,&expectedTokens[i].literal)
        ) {
            std.debug.print("failed at \"{d}\"\nexp: \"{}\",\ngot: \"{}\"\n", .{ i,expectedTokens[i],tok });
            return error.TestFailure;
        }
        i+=1;
        if(tok.type == .eof){
            break;
        }
    }
    if(i!=expectedTokens.len){
        std.debug.print("failed found \"{d}\" tokens want \"{d}\"\n", .{ i,expectedTokens.len });
        return error.TestFailure;
    }
}